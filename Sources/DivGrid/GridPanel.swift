import AppKit
import DivGridCore
import SwiftUI

/// Floating panel that shows the grid without taking focus from the app being resized.
final class GridPanel: NSPanel {
    enum Layout {
        static let width: CGFloat = 460
        static let inset: CGFloat = 10
        static let headerHeight: CGFloat = 36
        static let headerSpacing: CGFloat = 8
        static let idleAlpha: CGFloat = 0.6

        /// Panel size whose grid area keeps the cells' aspect ratio for `grid`.
        static func size(for grid: GridSize) -> NSSize {
            let gridHeight = (width - 2 * inset) * CGFloat(grid.rows) / CGFloat(grid.columns)
            return NSSize(width: width, height: gridHeight + 2 * inset + headerHeight + headerSpacing)
        }
    }

    var onCancel: (() -> Void)?

    init(contentSize: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isFloatingPanel = true
        level = .popUpMenu
        alphaValue = Layout.idleAlpha
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onCancel?() }

    func center(in screen: NSScreen) {
        let area = screen.visibleFrame
        setFrameOrigin(NSPoint(x: area.midX - frame.width / 2, y: area.midY - frame.height / 2))
    }

    func setHighlighted(_ highlighted: Bool) {
        animator().alphaValue = highlighted ? 1 : Layout.idleAlpha
    }
}

/// Lets the very first click on the (never-activating) panel reach the grid.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
