import AppKit
import Carbon.HIToolbox

extension Notification.Name {
    /// Posted while the shortcut recorder is active so the current hotkey doesn't swallow the keypress.
    static let hotKeyPause = Notification.Name("DivGrid.hotKeyPause")
    static let hotKeyChanged = Notification.Name("DivGrid.hotKeyChanged")
}

enum Settings {
    static let defaults = UserDefaults.standard

    static var columns: Int {
        get { max(2, defaults.object(forKey: "columns") as? Int ?? 6) }
        set { defaults.set(newValue, forKey: "columns") }
    }
    static var rows: Int {
        get { max(2, defaults.object(forKey: "rows") as? Int ?? 6) }
        set { defaults.set(newValue, forKey: "rows") }
    }
    /// Gap in points between the window and the edges of its grid region.
    static var margin: Double {
        get { defaults.object(forKey: "margin") as? Double ?? 0 }
        set { defaults.set(newValue, forKey: "margin") }
    }

    // MARK: Hotkey (default ⌃⌥Space)

    static var hotKeyCode: UInt32 {
        get { UInt32(defaults.object(forKey: "hotKeyCode") as? Int ?? kVK_Space) }
        set { defaults.set(Int(newValue), forKey: "hotKeyCode") }
    }
    /// Carbon modifier mask (controlKey, optionKey, shiftKey, cmdKey).
    static var hotKeyModifiers: UInt32 {
        get { UInt32(defaults.object(forKey: "hotKeyModifiers") as? Int ?? (controlKey | optionKey)) }
        set { defaults.set(Int(newValue), forKey: "hotKeyModifiers") }
    }
    static var hotKeyLabel: String {
        get { defaults.string(forKey: "hotKeyLabel") ?? "Space" }
        set { defaults.set(newValue, forKey: "hotKeyLabel") }
    }

    static var hotKeyDescription: String {
        let m = hotKeyModifiers
        var s = ""
        if m & UInt32(controlKey) != 0 { s += "⌃" }
        if m & UInt32(optionKey) != 0 { s += "⌥" }
        if m & UInt32(shiftKey) != 0 { s += "⇧" }
        if m & UInt32(cmdKey) != 0 { s += "⌘" }
        return s + hotKeyLabel
    }

    static func carbonModifiers(_ f: NSEvent.ModifierFlags) -> UInt32 {
        var m = 0
        if f.contains(.control) { m |= controlKey }
        if f.contains(.option) { m |= optionKey }
        if f.contains(.shift) { m |= shiftKey }
        if f.contains(.command) { m |= cmdKey }
        return UInt32(m)
    }

    static func keyLabel(for e: NSEvent) -> String {
        let special: [Int: String] = [
            kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
            kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
            kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        ]
        return special[Int(e.keyCode)] ?? e.charactersIgnoringModifiers?.uppercased() ?? "Key \(e.keyCode)"
    }
}
