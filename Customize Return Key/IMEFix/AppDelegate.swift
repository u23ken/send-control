import AppKit
import QuartzCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let eventTapManager = EventTapManager()
    private let canonicalInstallPath = "/Applications/Send Control.app"
    private let tapStartRetryDelay: TimeInterval = 1.0
    private let maxTapStartRetries = 5
    private let healthCheckInterval: TimeInterval = 5.0
    private let minAutoRestartInterval: TimeInterval = 10.0
    private let desiredProtectionDefaultsKey = "SendControlDesiredProtectionEnabled"
    private var tapStartRetryCount = 0
    private var pendingRetryWorkItem: DispatchWorkItem?
    private var healthCheckTimer: Timer?
    private var lastAutoRestartAttemptAt = Date.distantPast
    private var missingAccessibilityPermission = false
    private var missingInputMonitoringPermission = false
    private var lastLoggedPermissionSignature = ""
    private var startPromptForPermissions = false
    private var startOpenSettingsOnFailure = false
    private var desiredProtectionEnabled = true

    private var statusItem: NSStatusItem!
    private let headerMenuItem = NSMenuItem()
    private lazy var headerView: ProtectionHeaderMenuView = {
        let view = ProtectionHeaderMenuView(frame: NSRect(x: 0, y: 0, width: 320, height: 36))
        view.onToggle = { [weak self] isOn in
            self?.setProtectionEnabled(isOn, trigger: "header-switch", userInitiated: true)
        }
        return view
    }()
    private lazy var quitMenuItem: NSMenuItem = {
        let item = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        item.keyEquivalentModifierMask = [.command]
        item.target = self
        return item
    }()

    private var isEnabled = false {
        didSet { updateMenuState() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        SendControlLog.appInfo("App launched.")
        SendControlLog.appInfo("Bundle: \(Bundle.main.bundleIdentifier ?? "unknown"), path: \(Bundle.main.bundleURL.path)")
        guard enforceCanonicalInstallLocation() else {
            return
        }
        guard enforceSingleRunningInstance() else {
            return
        }

        setupMenuBar()
        loadDesiredProtectionState()

        eventTapManager.shouldRemapBundleID = { [weak self] bundleID in
            self?.shouldProtect(bundleID: bundleID) ?? false
        }
        eventTapManager.onStateChanged = { [weak self] enabled in
            DispatchQueue.main.async {
                SendControlLog.appInfo("Event tap state changed: \(enabled ? "ON" : "OFF").")
                self?.isEnabled = enabled
            }
        }

        _ = refreshPermissionState(prompt: false)
        startHealthCheckTimer()

        if desiredProtectionEnabled {
            if missingAccessibilityPermission || missingInputMonitoringPermission {
                SendControlLog.appWarning("Launch auto-start skipped because permissions are missing. Waiting for user to grant permission.")
                isEnabled = false
                updateMenuState()
            } else {
                SendControlLog.appInfo("Auto-starting event tap on launch.")
                startEventTapWithRetry(
                    trigger: "launch-auto",
                    promptForPermissions: false,
                    openSettingsOnFailure: false
                )
            }
        } else {
            SendControlLog.appInfo("Protection is OFF by saved preference.")
            eventTapManager.stop()
            isEnabled = false
            updateMenuState()
        }
    }

    @discardableResult
    private func enforceCanonicalInstallLocation() -> Bool {
        let currentURL = Bundle.main.bundleURL.resolvingSymlinksInPath().standardizedFileURL
        let canonicalURL = URL(fileURLWithPath: canonicalInstallPath, isDirectory: true)
            .resolvingSymlinksInPath()
            .standardizedFileURL

        guard currentURL.path != canonicalURL.path else {
            return true
        }

        guard FileManager.default.fileExists(atPath: canonicalURL.path) else {
            SendControlLog.appWarning(
                "Running from non-canonical path because canonical app is missing: \(currentURL.path)"
            )
            return true
        }

        SendControlLog.appWarning(
            "Non-canonical launch detected: \(currentURL.path). Redirecting to \(canonicalURL.path)."
        )

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: canonicalURL, configuration: configuration) { _, error in
            if let error {
                SendControlLog.appError("Failed to launch canonical app: \(error.localizedDescription)")
            }
            NSApp.terminate(nil)
        }
        return false
    }

    @objc private func quitApp() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        cancelPendingTapRetry()
        eventTapManager.stop()
        NSApp.terminate(nil)
    }

    private func startEventTapWithRetry(
        trigger: String,
        promptForPermissions: Bool,
        openSettingsOnFailure: Bool
    ) {
        startPromptForPermissions = promptForPermissions
        startOpenSettingsOnFailure = openSettingsOnFailure
        cancelPendingTapRetry()
        let hasPermissions = refreshPermissionState(prompt: promptForPermissions)
        if !hasPermissions {
            SendControlLog.appWarning(
                "Permissions appear missing before start (\(trigger)); attempting event tap start anyway."
            )
        }

        tapStartRetryCount = 0
        attemptStartEventTap(trigger: trigger)
    }

    private func attemptStartEventTap(trigger: String) {
        guard desiredProtectionEnabled else {
            SendControlLog.appDebug("Skipping start attempt because protection is OFF.")
            return
        }

        let attempt = tapStartRetryCount + 1
        SendControlLog.appInfo("Starting event tap (trigger: \(trigger), attempt: \(attempt)/\(maxTapStartRetries + 1)).")
        // Recreate the tap each attempt to avoid stale tap state after OFF -> ON toggles.
        eventTapManager.restartTap()

        if eventTapManager.isRunning && eventTapManager.isTapEnabledBySystem {
            SendControlLog.appInfo("Event tap started successfully.")
            isEnabled = true
            cancelPendingTapRetry()
            return
        }

        guard tapStartRetryCount < maxTapStartRetries else {
            SendControlLog.appError("Event tap start failed after retries.")
            let hasPermissions = refreshPermissionState(prompt: startPromptForPermissions)
            if startOpenSettingsOnFailure {
                openMissingPermissionSettings()
            }
            if !hasPermissions {
                SendControlLog.appWarning("Event tap remains OFF because required permissions are not granted.")
            }
            eventTapManager.stop()
            isEnabled = false
            updateMenuState()
            return
        }

        tapStartRetryCount += 1
        let workItem = DispatchWorkItem { [weak self] in
            self?.attemptStartEventTap(trigger: trigger)
        }
        pendingRetryWorkItem = workItem
        SendControlLog.appDebug("Scheduling retry in \(tapStartRetryDelay)s.")
        DispatchQueue.main.asyncAfter(deadline: .now() + tapStartRetryDelay, execute: workItem)
    }

    private func cancelPendingTapRetry() {
        pendingRetryWorkItem?.cancel()
        pendingRetryWorkItem = nil
        tapStartRetryCount = 0
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusBarIcon()

        let menu = NSMenu()
        menu.autoenablesItems = false

        headerMenuItem.view = headerView
        menu.addItem(headerMenuItem)

        let headerSeparator = NSMenuItem.separator()
        menu.addItem(headerSeparator)
        menu.addItem(quitMenuItem)

        statusItem.menu = menu
        updateMenuState()
    }

    private func updateMenuState() {
        let permissionsMissing = missingAccessibilityPermission || missingInputMonitoringPermission

        headerView.updateState(isOn: isEnabled)
        updateStatusIconAppearance()

        if permissionsMissing && !isEnabled {
            statusItem.button?.toolTip = "Send Control: OFF (Permission required)"
        } else {
            statusItem.button?.toolTip = isEnabled ? "Send Control: ON" : "Send Control: OFF"
        }
    }

    private func updateStatusIconAppearance() {
        guard let button = statusItem.button else {
            return
        }

        // Dim the menu bar icon when protection is OFF.
        button.alphaValue = isEnabled ? 1.0 : 0.45
    }

    private func setProtectionEnabled(_ enabled: Bool, trigger: String, userInitiated: Bool) {
        if !enabled {
            desiredProtectionEnabled = false
            saveDesiredProtectionState()
            cancelPendingTapRetry()
            eventTapManager.stop()
            isEnabled = false
            SendControlLog.appInfo("Event tap manually turned OFF.")
            return
        }

        desiredProtectionEnabled = true
        saveDesiredProtectionState()

        if userInitiated {
            // Avoid repeated macOS permission prompt loops.
            let hasPermissions = refreshPermissionState(prompt: false)
            if !hasPermissions {
                openMissingPermissionSettings()
                SendControlLog.appWarning("Cannot turn ON yet because required permissions are missing.")
                isEnabled = false
                updateMenuState()
                return
            }
        }

        startEventTapWithRetry(
            trigger: trigger,
            promptForPermissions: false,
            openSettingsOnFailure: false
        )
    }

    private func configureStatusBarIcon() {
        guard let button = statusItem.button else {
            return
        }

        let icon = makeCustomStatusIcon()
        icon.isTemplate = true
        button.image = icon
        button.imagePosition = .imageOnly
        button.title = ""
        button.toolTip = "Send Control"
    }

    private func makeCustomStatusIcon() -> NSImage {
        if let url = Bundle.main.url(forResource: "MenuBarIconTemplate", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            // Keep the provided 32x32 template icon crisp by displaying at 16pt.
            image.size = NSSize(width: 16, height: 16)
            return image
        }

        SendControlLog.appWarning("Menu bar icon asset not found. Using fallback vector icon.")
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.labelColor.setFill()

        let keyBody = NSBezierPath(roundedRect: NSRect(x: 6.4, y: 1.4, width: 9.2, height: 15.1), xRadius: 1.4, yRadius: 1.4)
        keyBody.fill()

        let keyTab = NSBezierPath(roundedRect: NSRect(x: 2.3, y: 11.3, width: 5.4, height: 5.0), xRadius: 0.9, yRadius: 0.9)
        keyTab.fill()

        return image
    }

    private func shouldProtect(bundleID: String) -> Bool {
        guard !bundleID.isEmpty else {
            return false
        }

        if bundleID == Bundle.main.bundleIdentifier {
            return false
        }

        return true
    }

    private func openAccessibilityPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openInputMonitoringPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openMissingPermissionSettings() {
        if missingAccessibilityPermission {
            openAccessibilityPrivacySettings()
            return
        }

        if missingInputMonitoringPermission {
            openInputMonitoringPrivacySettings()
            return
        }

        openAccessibilityPrivacySettings()
    }

    @discardableResult
    private func refreshPermissionState(prompt: Bool) -> Bool {
        missingAccessibilityPermission = !eventTapManager.hasAccessibilityPermission(prompt: prompt)
        missingInputMonitoringPermission = !eventTapManager.hasInputMonitoringPermission(prompt: prompt)

        let previousSignature = lastLoggedPermissionSignature
        let permissionSignature = "\(missingAccessibilityPermission)-\(missingInputMonitoringPermission)"
        if permissionSignature != previousSignature {
            lastLoggedPermissionSignature = permissionSignature
            if missingAccessibilityPermission || missingInputMonitoringPermission {
                SendControlLog.appWarning(
                    "Required permissions missing (Accessibility=\(!missingAccessibilityPermission), InputMonitoring=\(!missingInputMonitoringPermission))."
                )
            } else {
                SendControlLog.appInfo("Required permissions are granted.")
            }
        }

        updateMenuState()
        return !missingAccessibilityPermission && !missingInputMonitoringPermission
    }

    @discardableResult
    private func enforceSingleRunningInstance() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return true
        }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { $0.processIdentifier != currentPID }

        guard others.isEmpty else {
            SendControlLog.appWarning("Another Send Control instance is already running. Exiting this instance.")
            others.first?.activate(options: [.activateIgnoringOtherApps])
            NSApp.terminate(nil)
            return false
        }

        return true
    }

    private func loadDesiredProtectionState() {
        if UserDefaults.standard.object(forKey: desiredProtectionDefaultsKey) == nil {
            desiredProtectionEnabled = true
            saveDesiredProtectionState()
            return
        }

        desiredProtectionEnabled = UserDefaults.standard.bool(forKey: desiredProtectionDefaultsKey)
    }

    private func saveDesiredProtectionState() {
        UserDefaults.standard.set(desiredProtectionEnabled, forKey: desiredProtectionDefaultsKey)
        updateMenuState()
    }

    private func startHealthCheckTimer() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(
            withTimeInterval: healthCheckInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performHealthCheck()
        }
        if let healthCheckTimer {
            RunLoop.main.add(healthCheckTimer, forMode: .common)
        }
    }

    private func performHealthCheck() {
        if !desiredProtectionEnabled {
            if isEnabled || eventTapManager.isRunning {
                SendControlLog.appInfo("Health check: protection disabled by preference. Stopping tap.")
                eventTapManager.stop()
                isEnabled = false
            }
            return
        }

        let tapHealthy = eventTapManager.isRunning && eventTapManager.isTapEnabledBySystem
        if tapHealthy {
            // Keep running even if preflight APIs transiently report false.
            _ = refreshPermissionState(prompt: false)
            if !isEnabled {
                isEnabled = true
            }
            return
        }

        let hasPermissions = refreshPermissionState(prompt: false)
        guard hasPermissions else {
            if isEnabled || eventTapManager.isRunning {
                SendControlLog.appWarning("Health check: permissions missing, forcing protection OFF.")
                eventTapManager.stop()
                isEnabled = false
            }
            return
        }

        guard pendingRetryWorkItem == nil else {
            return
        }

        let now = Date()
        if now.timeIntervalSince(lastAutoRestartAttemptAt) < minAutoRestartInterval {
            return
        }

        lastAutoRestartAttemptAt = now
        SendControlLog.appWarning("Health check detected inactive event tap. Attempting restart.")
        startEventTapWithRetry(
            trigger: "health-check",
            promptForPermissions: false,
            openSettingsOnFailure: false
        )
    }
}

private final class MenuHeaderToggleControl: NSControl {
    private static let animationDuration: TimeInterval = 0.18

    override var acceptsFirstResponder: Bool { false }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 38, height: 22)
    }

    @objc dynamic private var animationProgress: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    var isOn = false {
        didSet {
            guard oldValue != isOn else { return }
            let targetProgress: CGFloat = isOn ? 1 : 0
            guard window != nil else {
                animationProgress = targetProgress
                return
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().animationProgress = targetProgress
            }
        }
    }

    override class func defaultAnimation(forKey key: NSAnimatablePropertyKey) -> Any? {
        if key == "animationProgress" {
            return CABasicAnimation()
        }
        return super.defaultAnimation(forKey: key)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        focusRingType = .none
        wantsLayer = true
        animationProgress = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        focusRingType = .none
        wantsLayer = true
        animationProgress = 0
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        animationProgress = isOn ? 1 : 0
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let trackRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let cornerRadius = trackRect.height / 2
        let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: cornerRadius, yRadius: cornerRadius)
        let offTrackColor = NSColor(calibratedWhite: 0.82, alpha: 1.0)
        let onTrackColor = NSColor.controlAccentColor
        let trackColor = offTrackColor.blended(withFraction: animationProgress, of: onTrackColor) ?? onTrackColor
        trackColor.setFill()
        trackPath.fill()

        let strokeAlpha = max(0, 1 - animationProgress)
        if strokeAlpha > 0.001 {
            NSColor(calibratedWhite: 0.72, alpha: strokeAlpha).setStroke()
            trackPath.lineWidth = 1
            trackPath.stroke()
        }

        let thumbInset: CGFloat = 2
        let thumbDiameter = trackRect.height - (thumbInset * 2)
        let minThumbX = trackRect.minX + thumbInset
        let maxThumbX = trackRect.maxX - thumbInset - thumbDiameter
        let thumbX = minThumbX + ((maxThumbX - minThumbX) * animationProgress)
        let thumbRect = NSRect(
            x: thumbX,
            y: trackRect.minY + thumbInset,
            width: thumbDiameter,
            height: thumbDiameter
        )

        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.18)
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.set()

        NSColor.white.setFill()
        NSBezierPath(ovalIn: thumbRect).fill()
    }

    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
        sendAction(action, to: target)
    }
}

private final class ProtectionHeaderMenuView: NSView {
    var onToggle: ((Bool) -> Void)?

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Send Control")
        label.font = NSFont.menuFont(ofSize: 0)
        return label
    }()

    private lazy var toggleSwitch: MenuHeaderToggleControl = {
        let control = MenuHeaderToggleControl(frame: .zero)
        control.target = self
        control.action = #selector(handleSwitchChanged(_:))
        return control
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func updateState(isOn: Bool) {
        toggleSwitch.isOn = isOn
    }

    @objc private func handleSwitchChanged(_ sender: MenuHeaderToggleControl) {
        onToggle?(sender.isOn)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(toggleSwitch)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 320),
            heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            toggleSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            toggleSwitch.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggleSwitch.widthAnchor.constraint(equalToConstant: 38),
            toggleSwitch.heightAnchor.constraint(equalToConstant: 22)
        ])

        updateState(isOn: false)
    }
}
