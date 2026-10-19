import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let grid = GridController()
    private let settingsWindow = SettingsWindowController()
    private var statusBar: StatusBarController?
    private var hotKeys: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.lifecycle.info("DivGrid launched")
        AccessibilityPermission.isTrusted(prompt: true)

        grid.onOpenSettings = { [settingsWindow] in settingsWindow.show() }
        let statusBar = StatusBarController(
            onToggleGrid: { [grid] in grid.toggle() },
            onShowGrid: { [grid] in grid.show() },
            onOpenSettings: { [settingsWindow] in settingsWindow.show() })
        self.statusBar = statusBar
        hotKeys = HotKeyController(
            onTrigger: { [grid] in grid.toggle() },
            onShortcutChange: { shortcut in statusBar.updateShortcut(shortcut) })
    }
}
