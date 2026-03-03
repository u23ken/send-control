import AppKit
import ApplicationServices

final class EventTapManager {
    static let targetBundleIDPrefixes: [String] = [
        "com.anthropic.claudefordesktop",
        "com.anthropic.claude",
        "com.apple.Safari",
        "com.google.Chrome",
        "com.apple.WebKit.WebContent"
    ]
    static let targetAppNameKeywords: [String] = [
        "claude",
        "safari",
        "chrome",
        "web content"
    ]
    static let returnKeyCodes: Set<Int64> = [36, 76] // Return + keypad Enter
    private static let logPrefix = "[IMEFix]"
    private static let passthroughModifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
    private static let leftShiftKeyCode: CGKeyCode = 56
    private static let syntheticEventMarker: Int64 = 0x494D454658 // "IMEFX"

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var debugEventCount = 0
    private let maxDebugEventLogs = 20
    private var suppressOriginalReturnKeyUp = false

    private(set) var isRunning = false
    var onStateChanged: ((Bool) -> Void)?

    private static func log(_ message: String) {
        NSLog("%@", "\(logPrefix) \(message)")
    }

    func hasAccessibilityPermission(prompt: Bool) -> Bool {
        if prompt {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            let trusted = AXIsProcessTrustedWithOptions(options)
            if !trusted {
                Self.log("Accessibility permission is not granted.")
            }
            return trusted
        }

        return AXIsProcessTrusted()
    }

    func start() {
        guard Thread.isMainThread else {
            Self.log("start() called off main thread. Dispatching to main.")
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
            return
        }

        guard !isRunning else { return }

        if eventTap == nil {
            createEventTap()
        }

        guard let eventTap else {
            Self.log("Failed to start event tap because tapCreate returned nil.")
            updateRunningState(false)
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
        Self.log("Event tap enabled.")
        updateRunningState(true)
    }

    func stop() {
        guard let eventTap else {
            updateRunningState(false)
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        updateRunningState(false)
    }

    private func createEventTap() {
        Self.log("Creating CGEvent tap...")
        let keyDownMask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let keyUpMask = CGEventMask(1) << CGEventType.keyUp.rawValue
        let mask = keyDownMask | keyUpMask
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()
            return manager.handleEvent(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            Self.log("CGEvent.tapCreate failed (nil). Check Accessibility permission and app trust.")
            return
        }

        eventTap = tap
        Self.log("CGEvent.tapCreate succeeded.")
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CFRunLoopWakeUp(CFRunLoopGetMain())
            Self.log("Event tap source installed on main run loop.")
        } else {
            Self.log("Failed to create run loop source for event tap.")
        }
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticEventMarker {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown || type == .keyUp {
            debugEventCount += 1
            if debugEventCount <= maxDebugEventLogs {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
                Self.log("Callback #\(debugEventCount): type=\(type.rawValue), keyCode=\(keyCode), frontmost=\(frontmost)")
            } else if debugEventCount == maxDebugEventLogs + 1 {
                Self.log("Callback logging limit reached. Suppressing further callback logs.")
            }
        }

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                Self.log("Event tap was disabled by system and has been re-enabled.")
            }
            return Unmanaged.passUnretained(event)
        }

        guard isRunning, type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard Self.returnKeyCodes.contains(keyCode) else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyUp, suppressOriginalReturnKeyUp {
            suppressOriginalReturnKeyUp = false
            Self.log("Swallowed original Return keyUp (keyCode=\(keyCode)).")
            return nil
        }

        let frontBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "(unknown)"
        let isTarget = isTargetFrontmostApp()
        Self.log("Return detected: frontmost=\(frontBundleID), isTarget=\(isTarget), type=\(type.rawValue), keyCode=\(keyCode)")

        guard isTarget else {
            return Unmanaged.passUnretained(event)
        }

        if !event.flags.intersection(Self.passthroughModifiers).isEmpty {
            return Unmanaged.passUnretained(event)
        }

        if event.flags.contains(.maskShift) {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
            if postShiftReturnSequence(keyCode: CGKeyCode(keyCode), baseFlags: event.flags) {
                suppressOriginalReturnKeyUp = true
                Self.log("Converted Return to Shift+Return (synthetic sequence, keyCode=\(keyCode)).")
                return nil
            }

            Self.log("Failed to post synthetic Shift+Return; passing original event.")
            return Unmanaged.passUnretained(event)
        }

        return Unmanaged.passUnretained(event)
    }

    private func isTargetFrontmostApp() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        let bundleID = frontApp.bundleIdentifier ?? ""
        if Self.targetBundleIDPrefixes.contains(where: { bundleID.hasPrefix($0) }) {
            return true
        }

        let appName = (frontApp.localizedName ?? "").lowercased()
        return Self.targetAppNameKeywords.contains(where: { appName.contains($0) })
    }

    private func updateRunningState(_ enabled: Bool) {
        isRunning = enabled
        onStateChanged?(enabled)
    }

    private func postShiftReturnSequence(keyCode: CGKeyCode, baseFlags: CGEventFlags) -> Bool {
        let preservedFlags = baseFlags.subtracting(.maskShift)
        guard let shiftDown = makeSyntheticKeyEvent(
            keyCode: Self.leftShiftKeyCode,
            keyDown: true,
            flags: preservedFlags.union(.maskShift)
        ),
            let returnDown = makeSyntheticKeyEvent(
                keyCode: keyCode,
                keyDown: true,
                flags: preservedFlags.union(.maskShift)
            ),
            let returnUp = makeSyntheticKeyEvent(
                keyCode: keyCode,
                keyDown: false,
                flags: preservedFlags.union(.maskShift)
            ),
            let shiftUp = makeSyntheticKeyEvent(
                keyCode: Self.leftShiftKeyCode,
                keyDown: false,
                flags: preservedFlags
            ) else {
            return false
        }

        shiftDown.post(tap: .cghidEventTap)
        returnDown.post(tap: .cghidEventTap)
        returnUp.post(tap: .cghidEventTap)
        shiftUp.post(tap: .cghidEventTap)
        return true
    }

    private func makeSyntheticKeyEvent(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags) -> CGEvent? {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else {
            return nil
        }
        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventMarker)
        return event
    }
}
