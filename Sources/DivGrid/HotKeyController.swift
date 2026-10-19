import DivGridCore
import Foundation

/// Keeps the global hotkey in sync with the saved shortcut.
@MainActor
final class HotKeyController {
    private var hotKey: HotKey?
    private var observers: [NSObjectProtocol] = []
    private let onTrigger: () -> Void
    private let onShortcutChange: (HotKeyShortcut) -> Void

    init(onTrigger: @escaping () -> Void, onShortcutChange: @escaping (HotKeyShortcut) -> Void) {
        self.onTrigger = onTrigger
        self.onShortcutChange = onShortcutChange
        register()

        let center = NotificationCenter.default
        // While the shortcut recorder is listening, our own hotkey must not swallow the keypress.
        observers.append(
            center.addObserver(forName: .hotKeyPause, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.hotKey = nil }
            })
        observers.append(
            center.addObserver(forName: .hotKeyChanged, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.register() }
            })
    }

    private func register() {
        hotKey = nil  // Release the old registration first so the same combination can be reused.
        let shortcut = Preferences.shared.shortcut
        hotKey = HotKey(shortcut: shortcut) { [weak self] in self?.onTrigger() }
        onShortcutChange(shortcut)
    }
}

extension Notification.Name {
    static let hotKeyPause = Notification.Name("studio.g6.divgrid.hotKeyPause")
    static let hotKeyChanged = Notification.Name("studio.g6.divgrid.hotKeyChanged")
}
