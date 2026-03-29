import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
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
    private var permissionGuide = PermissionGuide()
    private var lastLoggedPermissionSignature = ""
    private var startPromptForPermissions = false
    private var startOpenSettingsOnFailure = false
    private var desiredProtectionEnabled = true
    private let exclusionStore = ExclusionStore()
    private lazy var exclusionMenuController = ExclusionMenuController(store: exclusionStore)

    private var statusItem: NSStatusItem!
    private let headerMenuItem = NSMenuItem()
    private lazy var headerView: ProtectionHeaderMenuView = {
        let view = ProtectionHeaderMenuView(frame: NSRect(x: 0, y: 0, width: 320, height: 36))
        view.onToggle = { [weak self] isOn in
            self?.setProtectionEnabled(isOn, trigger: "header-switch", userInitiated: true)
        }
        return view
    }()
    private lazy var aboutWindowController = AboutWindowController()
    private lazy var aboutMenuItem: NSMenuItem = {
        let item = NSMenuItem(title: "\u{200B}About Send Control", action: #selector(showAboutWindow), keyEquivalent: "")
        item.target = self
        return item
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

        eventTapManager.treatmentForBundleID = { [weak self] bundleID in
            guard bundleID != Bundle.main.bundleIdentifier else {
                return .passthrough
            }
            if self?.exclusionStore.contains(bundleID) == true {
                return .passthrough
            }
            return AppTreatment.classify(bundleID: bundleID)
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
            if permissionGuide.hasMissingPermissions {
                SendControlLog.appWarning("Launch auto-start skipped because permissions are missing. Waiting for user to grant permission.")
                isEnabled = false
                updateMenuState()
                DispatchQueue.main.async { [weak self] in
                    self?.permissionGuide.showGuideAlert()
                }
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
        // Terminate this instance regardless of whether the canonical copy launched successfully.
        // The user should not run the app from a non-canonical path.
        NSWorkspace.shared.openApplication(at: canonicalURL, configuration: configuration) { _, error in
            if let error {
                SendControlLog.appError("Failed to launch canonical app: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
        return false
    }

    @objc private func showAboutWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.aboutWindowController.present()
        }
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
                permissionGuide.openMissingSettings()
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

        menu.addItem(exclusionMenuController.menuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(aboutMenuItem)
        menu.addItem(quitMenuItem)

        menu.delegate = self
        statusItem.menu = menu
        updateMenuState()
    }

    func menuWillOpen(_ menu: NSMenu) {
        exclusionMenuController.lastFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func updateMenuState() {
        let permissionsMissing = permissionGuide.hasMissingPermissions

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
            let hasPermissions = refreshPermissionState(prompt: false)
            if !hasPermissions {
                SendControlLog.appWarning("Cannot turn ON yet because required permissions are missing.")
                isEnabled = false
                updateMenuState()
                permissionGuide.showGuideAlert()
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

    @discardableResult
    private func refreshPermissionState(prompt: Bool) -> Bool {
        let allGranted = permissionGuide.refresh(using: eventTapManager, prompt: prompt)

        let previousSignature = lastLoggedPermissionSignature
        let permissionSignature = "\(permissionGuide.missingAccessibility)-\(permissionGuide.missingInputMonitoring)"
        if permissionSignature != previousSignature {
            lastLoggedPermissionSignature = permissionSignature
            if permissionGuide.hasMissingPermissions {
                SendControlLog.appWarning(
                    "Required permissions missing (Accessibility=\(!permissionGuide.missingAccessibility), InputMonitoring=\(!permissionGuide.missingInputMonitoring))."
                )
            } else {
                SendControlLog.appInfo("Required permissions are granted.")
            }
        }

        updateMenuState()
        return allGranted
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
