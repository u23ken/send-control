import AppKit

final class MenuHeaderToggleControl: NSControl {
    override var acceptsFirstResponder: Bool { false }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 38, height: 22)
    }

    var isOn = false {
        didSet {
            guard oldValue != isOn else { return }
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        focusRingType = .none
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        focusRingType = .none
        wantsLayer = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let trackRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let cornerRadius = trackRect.height / 2
        let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: cornerRadius, yRadius: cornerRadius)
        let trackColor = isOn
            ? NSColor.controlAccentColor
            : NSColor(calibratedWhite: 0.82, alpha: 1.0)
        trackColor.setFill()
        trackPath.fill()

        if !isOn {
            NSColor(calibratedWhite: 0.72, alpha: 1.0).setStroke()
            trackPath.lineWidth = 1
            trackPath.stroke()
        }

        let thumbInset: CGFloat = 2
        let thumbDiameter = trackRect.height - (thumbInset * 2)
        let thumbX = isOn
            ? trackRect.maxX - thumbInset - thumbDiameter
            : trackRect.minX + thumbInset
        let thumbRect = NSRect(
            x: thumbX,
            y: trackRect.minY + thumbInset,
            width: thumbDiameter,
            height: thumbDiameter
        )

        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.18)
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.set()

        NSColor.white.setFill()
        NSBezierPath(ovalIn: thumbRect).fill()
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
        sendAction(action, to: target)
    }
}
