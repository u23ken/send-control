import AppKit

final class ProtectionHeaderMenuView: NSView {
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
