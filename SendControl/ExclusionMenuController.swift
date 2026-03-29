import AppKit

final class ExclusionMenuController: NSObject {
    let menuItem: NSMenuItem
    var lastFrontmostBundleID: String?

    private let store: ExclusionStore

    init(store: ExclusionStore) {
        self.store = store
        let item = NSMenuItem(title: "Excluded Apps", action: nil, keyEquivalent: "")
        self.menuItem = item
        super.init()

        item.submenu = buildSubmenu()

        store.onChange = { [weak self] in
            DispatchQueue.main.async {
                self?.rebuildSubmenu()
            }
        }
    }

    func rebuildSubmenu() {
        menuItem.submenu = buildSubmenu()
    }

    private func buildSubmenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        let sorted = store.bundleIDs.sorted()
        if sorted.isEmpty {
            let empty = NSMenuItem(title: "No excluded apps", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        } else {
            for bundleID in sorted {
                let displayName = appName(for: bundleID) ?? bundleID
                let title = displayName == bundleID ? bundleID : "\(displayName) (\(bundleID))"
                let item = NSMenuItem(title: title, action: #selector(removeExcludedApp(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = bundleID
                item.toolTip = "Click to remove exclusion"
                submenu.addItem(item)
            }
        }

        submenu.addItem(NSMenuItem.separator())

        let addFrontmost = NSMenuItem(title: "Exclude Frontmost App\u{2026}", action: #selector(addFrontmostApp), keyEquivalent: "")
        addFrontmost.target = self
        submenu.addItem(addFrontmost)

        return submenu
    }

    private func appName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return FileManager.default.displayName(atPath: url.path)
    }

    @objc private func removeExcludedApp(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        store.remove(bundleID)
    }

    @objc private func addFrontmostApp() {
        guard let bundleID = lastFrontmostBundleID,
              bundleID != Bundle.main.bundleIdentifier else {
            let alert = NSAlert()
            alert.messageText = "Could not detect frontmost app"
            alert.informativeText = "Switch to the app you want to exclude, then open this menu again."
            alert.runModal()
            return
        }

        let name = appName(for: bundleID) ?? bundleID
        let alert = NSAlert()
        alert.messageText = "Exclude \(name)?"
        alert.informativeText = "Return key remapping will be disabled in \(name) (\(bundleID))."
        alert.addButton(withTitle: "Exclude")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        store.add(bundleID)
    }

}
