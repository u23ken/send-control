import AppKit
import ApplicationServices

final class EventTapManager {
    static let returnKeyCodes: Set<Int64> = [36, 76] // Return + keypad Enter
    private static let passthroughModifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
    private static let syntheticEventMarker: Int64 = 0x494D454658 // "IMEFX"
    private static let leftShiftKeyCode: Int64 = 56

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var swallowedReturnKeyUpCounts: [Int64: Int] = [:]
    private var cachedFrontBundleID: String = ""
    private var frontAppObserver: NSObjectProtocol?
    private lazy var syntheticEventSource: CGEventSource? = {
        CGEventSource(stateID: .combinedSessionState)
    }()

    private(set) var isRunning = false
    var onStateChanged: ((Bool) -> Void)?
    var treatmentForBundleID: ((String) -> AppTreatment)?
    var isTapInstalled: Bool { eventTap != nil }
    var isTapEnabledBySystem: Bool {
        guard let eventTap else {
            return false
        }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    func hasAccessibilityPermission(prompt: Bool) -> Bool {
        if prompt {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            let trusted = AXIsProcessTrustedWithOptions(options)
            if !trusted {
                SendControlLog.eventTapWarning("Accessibility permission is not granted.")
            }
            return trusted
        }

        return AXIsProcessTrusted()
    }

    func hasInputMonitoringPermission(prompt: Bool) -> Bool {
        if prompt {
            return CGRequestListenEventAccess()
        }
        return CGPreflightListenEventAccess()
    }

    func start() {
        guard Thread.isMainThread else {
            SendControlLog.eventTapDebug("start() called off main thread. Dispatching to main.")
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
            return
        }

        guard !isRunning else { return }

        startFrontAppObserver()

        if eventTap == nil {
            createEventTap()
        }

        guard let eventTap else {
            SendControlLog.eventTapError("Failed to start event tap because tapCreate returned nil.")
            updateRunningState(false)
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
        if CGEvent.tapIsEnabled(tap: eventTap) {
            SendControlLog.eventTapInfo("Event tap enabled.")
            updateRunningState(true)
        } else {
            SendControlLog.eventTapError("Event tap could not be enabled by system.")
            updateRunningState(false)
        }
    }

    func stop() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.stop()
            }
            return
        }

        guard let eventTap else {
            swallowedReturnKeyUpCounts.removeAll()
            updateRunningState(false)
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        releaseTapResources()
        stopFrontAppObserver()
        updateRunningState(false)
    }

    func restartTap() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.restartTap()
            }
            return
        }

        releaseTapResources()
        updateRunningState(false)
        start()
    }

    private func createEventTap() {
        SendControlLog.eventTapDebug("Creating CGEvent tap.")
        releaseTapResources()
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
            SendControlLog.eventTapError("CGEvent.tapCreate failed. Check Accessibility permission and app trust.")
            return
        }

        eventTap = tap
        SendControlLog.eventTapInfo("CGEvent.tapCreate succeeded.")
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CFRunLoopWakeUp(CFRunLoopGetMain())
            SendControlLog.eventTapInfo("Event tap source installed on main run loop.")
        } else {
            SendControlLog.eventTapError("Failed to create run loop source for event tap.")
        }
    }

    /// Called from the CGEvent tap callback. The tap source is installed on the main run loop
    /// via `CFRunLoopAddSource(CFRunLoopGetMain(), ...)`, so this method runs on the main thread.
    /// `cachedFrontBundleID` is also written on the main thread (via `NSWorkspace` notification
    /// with `queue: .main`), so no additional synchronization is needed.
    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticEventMarker {
            return Unmanaged.passUnretained(event)
        }

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                SendControlLog.eventTapWarning("Event tap was disabled by system and has been re-enabled.")
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

        let frontBundleID = cachedFrontBundleID
        let treatment = treatmentForBundleID?(frontBundleID) ?? .passthrough

        guard treatment != .passthrough else {
            return Unmanaged.passUnretained(event)
        }

        if !event.flags.intersection(Self.passthroughModifiers).isEmpty {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyUp {
            if consumePendingReturnKeyUp(for: keyCode) {
                SendControlLog.eventTapDebug("Swallowed original Return keyUp.")
                return nil
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let success: Bool
        let baseFlags = event.flags.subtracting(.maskShift)
        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if event.flags.contains(.maskShift) {
            success = postReturnSequence(keyCode: keyCode, flags: baseFlags)
            if success {
                SendControlLog.eventTapDebug("Converted Shift+Return to Return.")
            }
        } else {
            switch treatment {
            case .remapTerminalSafe:
                success = postTerminalSafeShiftReturnSequence(keyCode: keyCode, flags: baseFlags)
                if success {
                    SendControlLog.eventTapDebug("Converted Return to terminal-safe Shift+Return.")
                }
            case .remapStandard:
                success = postShiftReturnSequence(keyCode: keyCode, flags: baseFlags)
                if success {
                    SendControlLog.eventTapDebug("Converted Return to Shift+Return.")
                }
            case .passthrough:
                return Unmanaged.passUnretained(event)
            }
        }

        guard success else {
            SendControlLog.eventTapWarning("Synthetic remap failed; passing original Return through.")
            return Unmanaged.passUnretained(event)
        }

        if !isAutoRepeat {
            markPendingReturnKeyUp(for: keyCode)
        }
        return nil
    }

    private func updateRunningState(_ enabled: Bool) {
        isRunning = enabled
        onStateChanged?(enabled)
    }

    private func markPendingReturnKeyUp(for keyCode: Int64) {
        swallowedReturnKeyUpCounts[keyCode, default: 0] += 1
    }

    private func consumePendingReturnKeyUp(for keyCode: Int64) -> Bool {
        guard let count = swallowedReturnKeyUpCounts[keyCode], count > 0 else {
            return false
        }

        if count == 1 {
            swallowedReturnKeyUpCounts.removeValue(forKey: keyCode)
        } else {
            swallowedReturnKeyUpCounts[keyCode] = count - 1
        }
        return true
    }

    /// Posts Shift-down, Return-down (no .maskShift), Return-up (no .maskShift), Shift-up.
    /// The Return events intentionally carry no .maskShift so that modifyOtherKeys /
    /// kitty-protocol terminals encode a plain newline rather than an escape sequence.
    private func postTerminalSafeShiftReturnSequence(keyCode: Int64, flags: CGEventFlags) -> Bool {
        postSyntheticKeyEvent(keyCode: Self.leftShiftKeyCode, isKeyDown: true, flags: flags.union(.maskShift))
            && postSyntheticKeyEvent(keyCode: keyCode, isKeyDown: true, flags: flags)
            && postSyntheticKeyEvent(keyCode: keyCode, isKeyDown: false, flags: flags)
            && postSyntheticKeyEvent(keyCode: Self.leftShiftKeyCode, isKeyDown: false, flags: flags)
    }

    private func postShiftReturnSequence(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let returnFlags = flags.union(.maskShift)

        return postSyntheticKeyEvent(keyCode: Self.leftShiftKeyCode, isKeyDown: true, flags: returnFlags)
            && postSyntheticKeyEvent(keyCode: keyCode, isKeyDown: true, flags: returnFlags)
            && postSyntheticKeyEvent(keyCode: keyCode, isKeyDown: false, flags: returnFlags)
            && postSyntheticKeyEvent(keyCode: Self.leftShiftKeyCode, isKeyDown: false, flags: flags)
    }

    private func postReturnSequence(keyCode: Int64, flags: CGEventFlags) -> Bool {
        postSyntheticKeyEvent(keyCode: keyCode, isKeyDown: true, flags: flags)
            && postSyntheticKeyEvent(keyCode: keyCode, isKeyDown: false, flags: flags)
    }

    private func postSyntheticKeyEvent(keyCode: Int64, isKeyDown: Bool, flags: CGEventFlags) -> Bool {
        guard let event = CGEvent(
            keyboardEventSource: syntheticEventSource,
            virtualKey: CGKeyCode(keyCode),
            keyDown: isKeyDown
        ) else {
            SendControlLog.eventTapError("Failed to create synthetic key event.")
            return false
        }

        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventMarker)
        event.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
        event.post(tap: .cgSessionEventTap)
        return true
    }

    private func startFrontAppObserver() {
        cachedFrontBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        frontAppObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.cachedFrontBundleID = app?.bundleIdentifier ?? ""
        }
    }

    private func stopFrontAppObserver() {
        if let observer = frontAppObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            frontAppObserver = nil
        }
        cachedFrontBundleID = ""
    }

    private func releaseTapResources() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        swallowedReturnKeyUpCounts.removeAll()
    }
}
