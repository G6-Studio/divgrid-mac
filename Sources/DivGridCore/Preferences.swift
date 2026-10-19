import CoreGraphics
import Foundation

/// UserDefaults keys. Shared with SwiftUI's `@AppStorage` so the two never drift apart.
public enum PreferenceKey {
    public static let columns = "columns"
    public static let rows = "rows"
    public static let margin = "margin"
    public static let hotKeyCode = "hotKeyCode"
    public static let hotKeyModifiers = "hotKeyModifiers"
    public static let hotKeyLabel = "hotKeyLabel"
}

/// `UserDefaults` is thread-safe, so sharing a `Preferences` across threads is fine.
public struct Preferences: @unchecked Sendable {
    public static let marginRange: ClosedRange<Double> = 0...20
    public static let shared = Preferences(defaults: .standard)

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public var grid: GridSize {
        get {
            GridSize(
                columns: defaults.object(forKey: PreferenceKey.columns) as? Int ?? GridSize.default.columns,
                rows: defaults.object(forKey: PreferenceKey.rows) as? Int ?? GridSize.default.rows)
        }
        nonmutating set {
            defaults.set(newValue.columns, forKey: PreferenceKey.columns)
            defaults.set(newValue.rows, forKey: PreferenceKey.rows)
        }
    }

    /// Gap in points between a placed window and the edges of its grid region.
    public var margin: CGFloat {
        get { CGFloat((defaults.object(forKey: PreferenceKey.margin) as? Double ?? 0).clamped(to: Self.marginRange)) }
        nonmutating set { defaults.set(Double(newValue).clamped(to: Self.marginRange), forKey: PreferenceKey.margin) }
    }

    public var shortcut: HotKeyShortcut {
        get {
            let fallback = HotKeyShortcut.default
            // `exactly:` so a corrupt stored value falls back to the default instead of trapping.
            guard let code = (defaults.object(forKey: PreferenceKey.hotKeyCode) as? Int).flatMap(UInt32.init(exactly:)),
                let mask = (defaults.object(forKey: PreferenceKey.hotKeyModifiers) as? Int).flatMap(
                    UInt32.init(exactly:)),
                let label = defaults.string(forKey: PreferenceKey.hotKeyLabel)
            else { return fallback }
            return HotKeyShortcut(keyCode: code, modifiers: HotKeyModifiers(carbonMask: mask), label: label)
        }
        nonmutating set {
            defaults.set(Int(newValue.keyCode), forKey: PreferenceKey.hotKeyCode)
            defaults.set(Int(newValue.modifiers.carbonMask), forKey: PreferenceKey.hotKeyModifiers)
            defaults.set(newValue.label, forKey: PreferenceKey.hotKeyLabel)
        }
    }
}
