import AppKit

struct PermissionGuide {
    private(set) var missingAccessibility = false
    private(set) var missingInputMonitoring = false

    var hasMissingPermissions: Bool {
        missingAccessibility || missingInputMonitoring
    }

    mutating func refresh(using manager: EventTapManager, prompt: Bool) -> Bool {
        missingAccessibility = !manager.hasAccessibilityPermission(prompt: prompt)
        missingInputMonitoring = !manager.hasInputMonitoringPermission(prompt: prompt)
        return !missingAccessibility && !missingInputMonitoring
    }

    func showGuideAlert() {
        var missing: [String] = []
        if missingAccessibility {
            missing.append("Accessibility")
        }
        if missingInputMonitoring {
            missing.append("Input Monitoring")
        }
        guard !missing.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Send Control requires additional permissions"
        alert.informativeText = "To remap the Return key, please enable the following in System Settings > Privacy & Security:\n\n\u{2022} \(missing.joined(separator: "\n\u{2022} "))\n\nClick \"Open System Settings\" to go there now."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            openMissingSettings()
        }
    }

    func openMissingSettings() {
        if missingAccessibility {
            openSettings("Privacy_Accessibility")
            return
        }
        if missingInputMonitoring {
            openSettings("Privacy_ListenEvent")
            return
        }
        openSettings("Privacy_Accessibility")
    }

    private func openSettings(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
