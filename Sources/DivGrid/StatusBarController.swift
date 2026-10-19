import AppKit
import DivGridCore

/// The menu bar item: left click toggles the grid, right (or control) click opens the menu.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    /// Closing the menu briefly steals focus; the grid must wait until the previous app is frontmost again.
    /// Found by experiment, not derived from an API guarantee.
    private static let menuCloseDelay = Duration.milliseconds(150)

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let showItem = NSMenuItem()
    private let grantAccessItem = NSMenuItem()

    private let onToggleGrid: () -> Void
    private let onShowGrid: () -> Void
    private let onOpenSettings: () -> Void

    init(onToggleGrid: @escaping () -> Void, onShowGrid: @escaping () -> Void, onOpenSettings: @escaping () -> Void) {
        self.onToggleGrid = onToggleGrid
        self.onShowGrid = onShowGrid
        self.onOpenSettings = onOpenSettings
        super.init()

        showItem.action = #selector(showGrid)
        grantAccessItem.title = "Grant Accessibility Access…"
        grantAccessItem.action = #selector(grantAccess)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
        for item in [showItem, grantAccessItem, settingsItem] { item.target = self }

        let quitItem = NSMenuItem(
            title: "Quit DivGrid", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quitItem.target = NSApp

        menu.items = [showItem, grantAccessItem, settingsItem, .separator(), quitItem]
        menu.delegate = self

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "DivGrid")
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func updateShortcut(_ shortcut: HotKeyShortcut) {
        showItem.title = "Show Grid  (\(shortcut.displayString))"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        grantAccessItem.isHidden = AccessibilityPermission.isTrusted()
    }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            // Attach the menu only for this click, otherwise it would also capture left clicks.
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            onToggleGrid()
        }
    }

    @objc private func showGrid() {
        Task {
            try? await Task.sleep(for: Self.menuCloseDelay)
            onShowGrid()
        }
    }

    @objc private func grantAccess() {
        if !AccessibilityPermission.isTrusted(prompt: true) {
            NSWorkspace.shared.open(AccessibilityPermission.settingsURL)
        }
    }

    @objc private func openSettings() {
        onOpenSettings()
    }
}
