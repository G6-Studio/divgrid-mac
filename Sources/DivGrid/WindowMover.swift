import AppKit
import ApplicationServices

enum WindowMover {
    @discardableResult
    static func ensureAccessibility(prompt: Bool = false) -> Bool {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): prompt] as CFDictionary)
    }

    /// The focused window of the frontmost (non-self) app.
    static func frontWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success
        else { return nil }
        return (value as! AXUIElement)
    }

    static func pid(of w: AXUIElement) -> pid_t? {
        var pid: pid_t = 0
        return AXUIElementGetPid(w, &pid) == .success ? pid : nil
    }

    static func title(of w: AXUIElement) -> String {
        var v: CFTypeRef?
        AXUIElementCopyAttributeValue(w, kAXTitleAttribute as CFString, &v)
        return v as? String ?? ""
    }

    /// Window frame in AppKit screen coordinates (bottom-left origin).
    static func appKitFrame(of w: AXUIElement) -> NSRect? {
        guard let f = frame(of: w) else { return nil }
        let primaryH = NSScreen.screens.first?.frame.height ?? 0
        return NSRect(x: f.minX, y: primaryH - f.maxY, width: f.width, height: f.height)
    }

    /// Screen currently holding the window (by its center), falling back to the main screen.
    static func screen(of window: AXUIElement) -> NSScreen? {
        guard let frame = frame(of: window) else { return NSScreen.main }
        let primaryH = NSScreen.screens.first?.frame.height ?? 0
        let center = CGPoint(x: frame.midX, y: primaryH - frame.midY)
        return NSScreen.screens.first { $0.frame.contains(center) } ?? NSScreen.main
    }

    /// Place `window` on the given inclusive cell range of `screen`'s visible frame.
    static func place(_ window: AXUIElement, screen: NSScreen,
                      cols: ClosedRange<Int>, rows: ClosedRange<Int>) {
        let vf = screen.visibleFrame
        let cw = vf.width / CGFloat(Settings.columns)
        let rh = vf.height / CGFloat(Settings.rows)
        let m = CGFloat(Settings.margin)

        let nsTop = vf.maxY - CGFloat(rows.lowerBound) * rh
        let primaryH = NSScreen.screens.first?.frame.height ?? 0
        var pos = CGPoint(x: vf.minX + CGFloat(cols.lowerBound) * cw + m, y: primaryH - nsTop + m)
        var size = CGSize(width: CGFloat(cols.count) * cw - 2 * m, height: CGFloat(rows.count) * rh - 2 * m)

        // Size → position → size handles windows that clamp when moving across displays.
        set(window, kAXSizeAttribute, &size, .cgSize)
        set(window, kAXPositionAttribute, &pos, .cgPoint)
        set(window, kAXSizeAttribute, &size, .cgSize)
    }

    private static func set(_ w: AXUIElement, _ attr: String, _ v: inout CGPoint, _ type: AXValueType) {
        if let ax = AXValueCreate(type, &v) { AXUIElementSetAttributeValue(w, attr as CFString, ax) }
    }

    private static func set(_ w: AXUIElement, _ attr: String, _ v: inout CGSize, _ type: AXValueType) {
        if let ax = AXValueCreate(type, &v) { AXUIElementSetAttributeValue(w, attr as CFString, ax) }
    }

    static func frame(of w: AXUIElement) -> CGRect? {
        var p: CFTypeRef?, s: CFTypeRef?
        var pos = CGPoint.zero, size = CGSize.zero
        guard AXUIElementCopyAttributeValue(w, kAXPositionAttribute as CFString, &p) == .success,
              AXUIElementCopyAttributeValue(w, kAXSizeAttribute as CFString, &s) == .success,
              AXValueGetValue(p as! AXValue, .cgPoint, &pos),
              AXValueGetValue(s as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: pos, size: size)
    }
}
