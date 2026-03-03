import AppKit
import CoreServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let eventTapManager = EventTapManager()
    private let logPrefix = "[IMEFix]"
    private let tapStartRetryDelay: TimeInterval = 1.0
    private let maxTapStartRetries = 5
    private var tapStartRetryCount = 0
    private var pendingRetryWorkItem: DispatchWorkItem?
    private var newestBuildURL: URL?
    private var isRunningOutdatedBuild = false

    private var statusItem: NSStatusItem!
    private let statusMenuItem = NSMenuItem(title: "IMEFix: OFF", action: nil, keyEquivalent: "")
    private let runningPathMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private lazy var toggleMenuItem: NSMenuItem = {
        let item = NSMenuItem(title: "Turn ON", action: #selector(toggleIMEFix), keyEquivalent: "")
        item.target = self
        return item
    }()
    private lazy var useNewestBuildMenuItem: NSMenuItem = {
        let item = NSMenuItem(title: "Use Newest Build", action: #selector(switchToNewestBuild), keyEquivalent: "")
        item.target = self
        item.isHidden = true
        return item
    }()

    private var isEnabled = false {
        didSet { updateMenuState() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("\(logPrefix) App launched.")
        setupMenuBar()
        eventTapManager.onStateChanged = { [weak self] enabled in
            print("[IMEFix] Event tap state changed: \(enabled ? "ON" : "OFF")")
            self?.isEnabled = enabled
        }

        refreshBuildSelection()
        if isRunningOutdatedBuild {
            print("\(logPrefix) Outdated build detected at \(Bundle.main.bundleURL.path). Attempting to launch newer build.")
            switchToNewestBuild()
            return
        }

        // Try to start directly; relying only on preflight checks can cause false negatives.
        startEventTapWithRetry(trigger: "launch")
    }

    @objc private func toggleIMEFix() {
        refreshBuildSelection()
        if isRunningOutdatedBuild {
            print("\(logPrefix) Refusing to toggle old build. Switching to newest build first.")
            switchToNewestBuild()
            return
        }

        if isEnabled {
            cancelPendingTapRetry()
            eventTapManager.stop()
            isEnabled = false
            print("\(logPrefix) Event tap manually turned OFF.")
            return
        }

        startEventTapWithRetry(trigger: "menu-toggle")
    }

    @objc private func quitApp() {
        cancelPendingTapRetry()
        NSApp.terminate(nil)
    }

    @objc private func switchToNewestBuild() {
        refreshBuildSelection()
        guard let newestBuildURL else {
            print("\(logPrefix) No newer build candidate found.")
            return
        }

        let currentURL = normalizeAppURL(Bundle.main.bundleURL.path)
        guard newestBuildURL.path != currentURL.path else {
            print("\(logPrefix) Current build is already the newest build.")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: newestBuildURL, configuration: config) { [weak self] _, error in
            if let error {
                print("[IMEFix] Failed to launch newer build: \(error.localizedDescription)")
                self?.refreshBuildSelection()
                self?.updateMenuState()
                return
            }

            print("[IMEFix] Launched newer build at \(newestBuildURL.path). Terminating current build.")
            NSApp.terminate(nil)
        }
    }

    private func startEventTapWithRetry(trigger: String) {
        cancelPendingTapRetry()
        tapStartRetryCount = 0
        attemptStartEventTap(trigger: trigger)
    }

    private func attemptStartEventTap(trigger: String) {
        let attempt = tapStartRetryCount + 1
        print("\(logPrefix) Starting event tap (trigger: \(trigger), attempt: \(attempt)/\(maxTapStartRetries + 1)).")
        eventTapManager.start()

        if eventTapManager.isRunning {
            print("\(logPrefix) Event tap started successfully.")
            isEnabled = true
            cancelPendingTapRetry()
            return
        }

        guard tapStartRetryCount < maxTapStartRetries else {
            print("\(logPrefix) Event tap start failed after retries.")
            _ = eventTapManager.hasAccessibilityPermission(prompt: true)
            openAccessibilityPrivacySettings()
            isEnabled = false
            return
        }

        tapStartRetryCount += 1
        let workItem = DispatchWorkItem { [weak self] in
            self?.attemptStartEventTap(trigger: trigger)
        }
        pendingRetryWorkItem = workItem
        print("\(logPrefix) Scheduling retry in \(tapStartRetryDelay)s.")
        DispatchQueue.main.asyncAfter(deadline: .now() + tapStartRetryDelay, execute: workItem)
    }

    private func cancelPendingTapRetry() {
        pendingRetryWorkItem?.cancel()
        pendingRetryWorkItem = nil
        tapStartRetryCount = 0
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "IMEFix"

        let menu = NSMenu()
        statusMenuItem.isEnabled = false
        runningPathMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(toggleMenuItem)
        menu.addItem(runningPathMenuItem)
        menu.addItem(useNewestBuildMenuItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenuState()
    }

    private func updateMenuState() {
        refreshBuildSelection()

        if isRunningOutdatedBuild {
            statusMenuItem.title = "⚠️ Running old build"
            toggleMenuItem.title = "Turn ON"
            useNewestBuildMenuItem.isHidden = false
            useNewestBuildMenuItem.title = "Use Newest Build"
            return
        }

        statusMenuItem.title = "IMEFix: \(isEnabled ? "ON" : "OFF")"
        toggleMenuItem.title = isEnabled ? "Turn OFF" : "Turn ON"
        useNewestBuildMenuItem.isHidden = true
    }

    private func refreshBuildSelection() {
        let currentURL = normalizeAppURL(Bundle.main.bundleURL.path)
        runningPathMenuItem.title = "Running: \(currentURL.path)"

        var candidateURLs = [currentURL]
        let applicationsURL = normalizeAppURL("/Applications/IMEFix.app")
        let userApplicationsURL = normalizeAppURL("\(NSHomeDirectory())/Applications/IMEFix.app")
        let preferredInstallPaths = Set([applicationsURL.path, userApplicationsURL.path, currentURL.path])

        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            let registered = registeredAppURLs(for: bundleIdentifier).filter { preferredInstallPaths.contains($0.path) }
            if !registered.isEmpty {
                let list = registered.map { $0.path }.joined(separator: ", ")
                print("\(logPrefix) LaunchServices candidates: \(list)")
            }
            candidateURLs.append(contentsOf: registered)
        }

        // Only treat installed app locations as upgrade candidates.
        let candidatePaths = [
            applicationsURL.path,
            userApplicationsURL.path
        ]
        candidateURLs.append(contentsOf: candidatePaths.map(normalizeAppURL))

        var uniquePaths = Set<String>()
        let candidates = candidateURLs.compactMap { appURL -> URL? in
            let normalized = normalizeAppURL(appURL.path)
            guard FileManager.default.fileExists(atPath: normalized.path) else {
                return nil
            }
            guard uniquePaths.insert(normalized.path).inserted else {
                return nil
            }
            guard isSelfBundleIdentifier(at: normalized) else {
                return nil
            }
            return normalized
        }

        let sortedCandidates = candidates.sorted {
            modificationDate(for: $0) > modificationDate(for: $1)
        }
        if !sortedCandidates.isEmpty {
            let list = sortedCandidates
                .map { "\($0.path) @ \(modificationDate(for: $0))" }
                .joined(separator: " | ")
            print("\(logPrefix) Resolved build candidates: \(list)")
        }

        let newest = candidates.max { lhs, rhs in
            modificationDate(for: lhs) < modificationDate(for: rhs)
        }
        newestBuildURL = newest
        isRunningOutdatedBuild = newest?.path != currentURL.path
    }

    private func modificationDate(for appURL: URL) -> Date {
        let executableURL = appURL.appendingPathComponent("Contents/MacOS/IMEFix")
        if let values = try? executableURL.resourceValues(forKeys: [.contentModificationDateKey]),
           let date = values.contentModificationDate {
            return date
        }

        if let values = try? appURL.resourceValues(forKeys: [.contentModificationDateKey]),
           let date = values.contentModificationDate {
            return date
        }

        return .distantPast
    }

    private func normalizeAppURL(_ path: String) -> URL {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    }

    private func openAccessibilityPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func registeredAppURLs(for bundleIdentifier: String) -> [URL] {
        guard let unmanaged = LSCopyApplicationURLsForBundleIdentifier(bundleIdentifier as CFString, nil) else {
            return []
        }

        let rawArray = unmanaged.takeRetainedValue() as NSArray
        return rawArray.compactMap { item in
            guard let url = item as? URL else {
                return nil
            }
            return normalizeAppURL(url.path)
        }
    }

    private func isSelfBundleIdentifier(at appURL: URL) -> Bool {
        guard let mainBundleID = Bundle.main.bundleIdentifier else {
            return true
        }

        guard let candidateBundle = Bundle(url: appURL),
              let candidateBundleID = candidateBundle.bundleIdentifier else {
            return false
        }
        return candidateBundleID == mainBundleID
    }
}
