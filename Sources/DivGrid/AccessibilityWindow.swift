import AppKit
import ApplicationServices
import DivGridCore

enum AccessibilityPermission {
    /// Whether the app may control other apps' windows. With `prompt`, asks macOS to show its dialog.
    @discardableResult
    static func isTrusted(prompt: Bool = false) -> Bool {
        // The literal is the value of kAXTrustedCheckOptionPrompt, which Swift 6 won't let us reference.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": prompt] as CFDictionary)
    }

    static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
}

enum WindowError: Error, CustomStringConvertible {
    case permissionDenied
    case notSettable
    case cannotComplete
    case invalidWindow
    case other(AXError)

    init(_ error: AXError) {
        switch error {
        case .apiDisabled: self = .permissionDenied
        case .attributeUnsupported, .actionUnsupported: self = .notSettable
        case .cannotComplete: self = .cannotComplete
        case .invalidUIElement: self = .invalidWindow
        default: self = .other(error)
        }
    }

    var description: String {
        switch self {
        case .permissionDenied: "Accessibility permission denied"
        case .notSettable: "window does not allow this change"
        case .cannotComplete: "app did not respond"
        case .invalidWindow: "window no longer exists"
        case .other(let error): "Accessibility error \(error.rawValue)"
        }
    }
}

/// A window of another app, reached through the Accessibility API.
struct AccessibilityWindow {
    let element: AXUIElement

    /// The focused window of the frontmost app, ignoring our own windows.
    static func focused() -> AccessibilityWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication,
            app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return nil }
        return focused(pid: app.processIdentifier)
    }

    static func focused(pid: pid_t) -> AccessibilityWindow? {
        let app = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value)
        guard error == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            // `.noValue` just means the app has no focused window.
            if error != .success && error != .noValue {
                Log.window.debug("No focused window for pid \(pid): \(WindowError(error), privacy: .public)")
            }
            return nil
        }
        return AccessibilityWindow(element: unsafeDowncast(value, to: AXUIElement.self))
    }

    var pid: pid_t? {
        var pid: pid_t = 0
        return AXUIElementGetPid(element, &pid) == .success ? pid : nil
    }

    var title: String {
        copyValue(kAXTitleAttribute) as? String ?? ""
    }

    // MARK: Geometry

    private static var primaryDisplayHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    /// Frame in AppKit screen coordinates (bottom-left origin).
    var appKitFrame: CGRect? {
        axFrame.map { ScreenCoordinates.appKitRect(fromAX: $0, primaryHeight: Self.primaryDisplayHeight) }
    }

    /// Moves and resizes the window to `frame` (AppKit coordinates).
    /// Every step is attempted even if one fails (say, a fixed-size window); the first real failure is thrown.
    func setAppKitFrame(_ frame: CGRect) throws {
        let target = ScreenCoordinates.axRect(fromAppKit: frame, primaryHeight: Self.primaryDisplayHeight)
        // Size, position, size again: a window moved across displays can clamp its size to the old
        // display, so the final resize makes the size stick.
        // The first resize only prepares the move, so only the move and the final resize count as failures.
        _ = setSize(target.size)
        let results = [setPosition(target.origin), setSize(target.size)]
        if let failure = results.first(where: { $0 != .success }) {
            throw WindowError(failure)
        }
    }

    // MARK: Accessibility plumbing

    private var axFrame: CGRect? {
        guard let position = copyValue(kAXPositionAttribute), let size = copyValue(kAXSizeAttribute),
            CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID()
        else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        guard AXValueGetValue(unsafeDowncast(position, to: AXValue.self), .cgPoint, &origin),
            AXValueGetValue(unsafeDowncast(size, to: AXValue.self), .cgSize, &extent)
        else { return nil }
        return CGRect(origin: origin, size: extent)
    }

    private func copyValue(_ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    private func setSize(_ size: CGSize) -> AXError {
        var size = size
        return withUnsafePointer(to: &size) { setValue(kAXSizeAttribute, .cgSize, $0) }
    }

    private func setPosition(_ origin: CGPoint) -> AXError {
        var origin = origin
        return withUnsafePointer(to: &origin) { setValue(kAXPositionAttribute, .cgPoint, $0) }
    }

    private func setValue(_ attribute: String, _ type: AXValueType, _ pointer: UnsafeRawPointer) -> AXError {
        guard let value = AXValueCreate(type, pointer) else { return .illegalArgument }
        return AXUIElementSetAttributeValue(element, attribute as CFString, value)
    }
}
