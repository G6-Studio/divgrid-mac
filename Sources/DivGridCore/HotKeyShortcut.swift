import Carbon.HIToolbox

public struct HotKeyModifiers: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let control = HotKeyModifiers(rawValue: 1 << 0)
    public static let option = HotKeyModifiers(rawValue: 1 << 1)
    public static let shift = HotKeyModifiers(rawValue: 1 << 2)
    public static let command = HotKeyModifiers(rawValue: 1 << 3)

    /// Modifier mask in the form Carbon's `RegisterEventHotKey` expects.
    public var carbonMask: UInt32 {
        var mask = 0
        if contains(.control) { mask |= controlKey }
        if contains(.option) { mask |= optionKey }
        if contains(.shift) { mask |= shiftKey }
        if contains(.command) { mask |= cmdKey }
        return UInt32(mask)
    }

    public init(carbonMask: UInt32) {
        var set: HotKeyModifiers = []
        if Int(carbonMask) & controlKey != 0 { set.insert(.control) }
        if Int(carbonMask) & optionKey != 0 { set.insert(.option) }
        if Int(carbonMask) & shiftKey != 0 { set.insert(.shift) }
        if Int(carbonMask) & cmdKey != 0 { set.insert(.command) }
        self = set
    }

    /// Symbols in the order macOS displays them: ⌃⌥⇧⌘.
    public var symbols: String {
        var s = ""
        if contains(.control) { s += "⌃" }
        if contains(.option) { s += "⌥" }
        if contains(.shift) { s += "⇧" }
        if contains(.command) { s += "⌘" }
        return s
    }
}

public struct HotKeyShortcut: Equatable, Sendable {
    /// ⌃⌥Space
    public static let `default` = HotKeyShortcut(
        keyCode: UInt32(kVK_Space), modifiers: [.control, .option], label: "Space")

    public let keyCode: UInt32
    public let modifiers: HotKeyModifiers
    /// Human-readable key name, stored because it depends on the keyboard layout at record time.
    public let label: String

    public init(keyCode: UInt32, modifiers: HotKeyModifiers, label: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.label = label
    }

    public var displayString: String { modifiers.symbols + label }

    private static let specialKeyLabels: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    /// Label for a key code; `characters` is the layout-specific text the key produces, if any.
    public static func label(forKeyCode keyCode: Int, characters: String?) -> String {
        specialKeyLabels[keyCode] ?? characters?.uppercased() ?? "Key \(keyCode)"
    }
}
