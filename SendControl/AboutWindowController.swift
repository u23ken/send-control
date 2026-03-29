import AppKit

final class AboutWindowController: NSWindowController {
    private static let windowSize = NSSize(width: 286, height: 288)

    init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.windowSize),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = AboutViewController()
        window.appearance = NSAppearance(named: .darkAqua)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.hasShadow = true
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.center()
        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func present() {
        guard let window else {
            return
        }

        if !window.isVisible {
            window.center()
        }

        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private final class AboutViewController: NSViewController {
    override func loadView() {
        view = AboutContentView(frame: NSRect(x: 0, y: 0, width: 286, height: 288))
    }
}

private final class AboutContentView: NSView {
    private let titleLabel = AboutContentView.makeLabel(
        string: AboutContentView.appName,
        font: .systemFont(ofSize: 18, weight: .semibold),
        color: NSColor(calibratedWhite: 0.94, alpha: 1.0)
    )
    private let subtitleLabel = AboutContentView.makeLabel(
        string: "Swap Return and Shift+Return",
        font: .systemFont(ofSize: 11.5, weight: .medium),
        color: NSColor(calibratedWhite: 0.83, alpha: 1.0)
    )
    private let versionLabel = AboutContentView.makeLabel(
        string: "version \(AboutContentView.versionString)",
        font: .systemFont(ofSize: 10, weight: .regular),
        color: NSColor(calibratedWhite: 0.88, alpha: 1.0)
    )
    private let copyrightLabel = AboutContentView.makeLabel(
        string: "©︎ 2003-2026 U23 inc.",
        font: .systemFont(ofSize: 9, weight: .regular),
        color: NSColor(calibratedWhite: 0.83, alpha: 1.0)
    )
    private let rightsReservedLabel = AboutContentView.makeLabel(
        string: "All Rights Reserved.",
        font: .systemFont(ofSize: 9, weight: .regular),
        color: NSColor(calibratedWhite: 0.83, alpha: 1.0)
    )
    private let iconView: NSImageView = {
        let view = NSImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.imageScaling = .scaleProportionallyUpOrDown
        view.imageAlignment = .alignCenter
        view.image = AboutContentView.appIcon
        return view
    }()

    private static let appName: String = {
        if let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }
        return "Send Control"
    }()

    private static let versionString: String = {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            return version
        }
        return ""
    }()

    private static let appIcon: NSImage? = {
        if let iconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String {
            let baseName = (iconName as NSString).deletingPathExtension
            let explicitExtension = (iconName as NSString).pathExtension
            let iconExtension = explicitExtension.isEmpty ? "icns" : explicitExtension
            if let url = Bundle.main.url(forResource: baseName, withExtension: iconExtension),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return NSApp.applicationIconImage
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var wantsUpdateLayer: Bool { true }

    override func makeBackingLayer() -> CALayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            NSColor(calibratedWhite: 0.18, alpha: 1.0).cgColor,
            NSColor(calibratedWhite: 0.14, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.borderWidth = 1
        gradientLayer.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.18).cgColor
        gradientLayer.masksToBounds = true
        return gradientLayer
    }

    override func updateLayer() {
        layer?.cornerRadius = 16
    }

    private func setup() {
        appearance = NSAppearance(named: .darkAqua)
        wantsLayer = true

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(versionLabel)
        addSubview(copyrightLabel)
        addSubview(rightsReservedLabel)

        let guide = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 22),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 86),
            iconView.heightAnchor.constraint(equalToConstant: 86),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 14),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 210),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 218),

            versionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 13),
            versionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            versionLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 210),

            copyrightLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 24),
            copyrightLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            copyrightLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 210),

            rightsReservedLabel.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: 2),
            rightsReservedLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            rightsReservedLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 210),
            rightsReservedLabel.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor, constant: -14)
        ])
    }

    private static func makeLabel(string: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: string)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
        label.textColor = color
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
        label.cell?.usesSingleLineMode = false
        return label
    }
}
