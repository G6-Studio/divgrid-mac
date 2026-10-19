import Foundation
import Testing

@testable import DivGridCore

@Suite struct PreferencesTests {
    /// A throwaway defaults domain so tests never touch the real preferences.
    private func makePreferences() -> Preferences {
        let name = "DivGridTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return Preferences(defaults: defaults)
    }

    @Test func defaults() {
        let prefs = makePreferences()
        #expect(prefs.grid == GridSize(columns: 6, rows: 6))
        #expect(prefs.margin == 0)
        #expect(prefs.shortcut == .default)
    }

    @Test func gridPersists() {
        let prefs = makePreferences()
        prefs.grid = GridSize(columns: 8, rows: 4)
        #expect(prefs.grid == GridSize(columns: 8, rows: 4))
    }

    @Test func outOfRangeStoredValuesClamp() {
        let prefs = makePreferences()
        prefs.grid = GridSize(columns: 500, rows: 1)
        #expect(prefs.grid == GridSize(columns: 20, rows: 2))
        prefs.margin = 99
        #expect(prefs.margin == 20)
        prefs.margin = -5
        #expect(prefs.margin == 0)
    }

    @Test func corruptStoredShortcutFallsBackToDefault() {
        let name = "DivGridTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(-1, forKey: PreferenceKey.hotKeyCode)
        defaults.set(Int.max, forKey: PreferenceKey.hotKeyModifiers)
        defaults.set("X", forKey: PreferenceKey.hotKeyLabel)
        #expect(Preferences(defaults: defaults).shortcut == .default)
    }

    @Test func shortcutPersists() {
        let prefs = makePreferences()
        let shortcut = HotKeyShortcut(keyCode: 5, modifiers: [.command, .shift], label: "G")
        prefs.shortcut = shortcut
        #expect(prefs.shortcut == shortcut)
        #expect(prefs.shortcut.displayString == "⇧⌘G")
    }
}
