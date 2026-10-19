import AppKit

/// Click-through accent outline drawn around the window that will be resized.
final class OutlinePanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = NSView()
        view.wantsLayer = true
        view.layer?.borderWidth = 3
        view.layer?.borderColor = NSColor.controlAccentColor.cgColor
        view.layer?.cornerRadius = 10
        view.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        contentView = view
    }
}
