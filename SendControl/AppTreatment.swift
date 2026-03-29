import Foundation

enum AppTreatment {
    /// Skip all remapping. The original event passes through unmodified.
    case passthrough
    /// Full Shift+Return sequence with .maskShift on the Return event.
    /// Correct for browsers and native Cocoa apps.
    case remapStandard
    /// Shift key events around a flag-clean Return event.
    /// Required for modifyOtherKeys / kitty-protocol terminals.
    case remapTerminalSafe

    private static let terminalSafeBundleIDPrefixes: [String] = [
        "com.mitchellh.ghostty",
    ]

    private static let passthroughBundleIDPrefixes: [String] = [
        "com.cmuxterm.app",
    ]

    static func classify(bundleID: String) -> AppTreatment {
        guard !bundleID.isEmpty else {
            return .passthrough
        }

        if passthroughBundleIDPrefixes.contains(where: { bundleID.hasPrefix($0) }) {
            return .passthrough
        }

        if terminalSafeBundleIDPrefixes.contains(where: { bundleID.hasPrefix($0) }) {
            return .remapTerminalSafe
        }

        return .remapStandard
    }
}
