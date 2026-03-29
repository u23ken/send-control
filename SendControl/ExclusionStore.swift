import Foundation

final class ExclusionStore {
    private static let defaultsKey = "SendControlExcludedBundleIDs"

    var onChange: (() -> Void)?

    private(set) var bundleIDs: Set<String> {
        didSet {
            guard oldValue != bundleIDs else { return }
            persist()
            onChange?()
        }
    }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.defaultsKey) ?? []
        bundleIDs = Set(saved)
    }

    func add(_ bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SendControlLog.appInfo("Adding exclusion: \(trimmed)")
        bundleIDs.insert(trimmed)
    }

    func remove(_ bundleID: String) {
        SendControlLog.appInfo("Removing exclusion: \(bundleID)")
        bundleIDs.remove(bundleID)
    }

    func contains(_ bundleID: String) -> Bool {
        bundleIDs.contains(bundleID)
    }

    private func persist() {
        UserDefaults.standard.set(Array(bundleIDs), forKey: Self.defaultsKey)
    }
}
