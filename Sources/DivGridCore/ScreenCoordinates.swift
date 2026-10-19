import CoreGraphics

/// Conversions between the two screen coordinate systems in play.
///
/// AppKit (`NSScreen`, `NSWindow`) uses a bottom-left origin; the Accessibility API uses a top-left
/// origin. Both are anchored to the primary display, so converting only needs that display's height.
public enum ScreenCoordinates {
    public static func appKitRect(fromAX rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        flipped(rect, primaryHeight: primaryHeight)
    }

    public static func axRect(fromAppKit rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        flipped(rect, primaryHeight: primaryHeight)
    }

    // Flipping the y axis is its own inverse, so one implementation serves both directions.
    private static func flipped(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}
