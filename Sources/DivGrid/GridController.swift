import AppKit
import Carbon.HIToolbox
import DivGridCore
import SwiftUI

/// Shows the grid on every display and applies the chosen region to the target window.
@MainActor
final class GridController {
    var onOpenSettings: (() -> Void)?

    private let tracker = TargetTracker()
    private var panels: [GridPanel] = []
    private var outline: OutlinePanel?
    private var escapeMonitor: Any?
    private var activeGrid = Preferences.shared.grid
    private var activeMargin: CGFloat = 0

    var isVisible: Bool { !panels.isEmpty }

    func toggle() {
        isVisible ? hide() : show()
    }

    /// One grid per display; a selection on any of them places the target window on that display.
    func show() {
        guard !isVisible else { return }
        guard AccessibilityPermission.isTrusted(prompt: true) else {
            Log.grid.notice("Not showing grid: Accessibility permission has not been granted")
            return
        }
        guard let window = AccessibilityWindow.focused() else {
            Log.grid.info("Not showing grid: no focused window to resize")
            NSSound.beep()
            return
        }

        activeGrid = Preferences.shared.grid
        activeMargin = Preferences.shared.margin
        panels = NSScreen.screens.map(makePanel(for:))
        panels.forEach { $0.orderFrontRegardless() }

        let outline = OutlinePanel()
        self.outline = outline
        tracker.onChange = { [weak self] in self?.updateOutline() }
        tracker.start(initial: window)

        // The panels never take focus, so Esc has to be observed globally.
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == UInt16(kVK_Escape) else { return }
            MainActor.assumeIsolated { self?.hide() }
        }
        Log.grid.info("Showing grid on \(self.panels.count) display(s)")
    }

    func hide() {
        panels.forEach { $0.orderOut(nil) }
        panels = []
        outline?.orderOut(nil)
        outline = nil
        tracker.stop()
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        escapeMonitor = nil
    }

    private func makePanel(for screen: NSScreen) -> GridPanel {
        let panel = GridPanel(contentSize: GridPanel.Layout.size(for: activeGrid))
        panel.onCancel = { [weak self] in self?.hide() }
        panel.contentView = FirstMouseHostingView(
            rootView: GridView(
                grid: activeGrid,
                target: tracker.info,
                onHover: { [weak panel] inside in panel?.setHighlighted(inside) },
                onSettings: { [weak self] in
                    self?.hide()
                    self?.onOpenSettings?()
                },
                onSelect: { [weak self] range in self?.apply(range, on: screen) }))
        panel.center(in: screen)
        return panel
    }

    private func updateOutline() {
        guard let frame = tracker.window?.appKitFrame else {
            outline?.orderOut(nil)
            return
        }
        outline?.setFrame(frame, display: true)
        outline?.orderFront(nil)
    }

    private func apply(_ range: CellRange, on screen: NSScreen) {
        // Closed on the next turn: this runs inside the grid view's own gesture callback.
        defer { Task { hide() } }
        guard let window = tracker.window else { return }
        let frame = GridGeometry.frame(
            for: range, in: screen.visibleFrame, grid: activeGrid, margin: activeMargin)
        do {
            try window.setAppKitFrame(frame)
        } catch {
            Log.window.error("Could not place window: \(error, privacy: .public)")
        }
    }
}
