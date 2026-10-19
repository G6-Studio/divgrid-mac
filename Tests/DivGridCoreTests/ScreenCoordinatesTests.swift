import CoreGraphics
import Testing

@testable import DivGridCore

@Suite struct ScreenCoordinatesTests {
    let primaryHeight: CGFloat = 1000

    @Test func windowAtTopOfPrimaryDisplay() {
        // AX y=0 is the top edge; in AppKit that is y = primaryHeight - height.
        let ax = CGRect(x: 100, y: 0, width: 400, height: 300)
        #expect(
            ScreenCoordinates.appKitRect(fromAX: ax, primaryHeight: primaryHeight)
                == CGRect(x: 100, y: 700, width: 400, height: 300))
    }

    @Test func roundTrip() {
        let original = CGRect(x: -300, y: 123, width: 640, height: 480)
        let ax = ScreenCoordinates.axRect(fromAppKit: original, primaryHeight: primaryHeight)
        #expect(ScreenCoordinates.appKitRect(fromAX: ax, primaryHeight: primaryHeight) == original)
    }

    @Test func displayAbovePrimaryHasNegativeAXY() {
        // A display stacked above the primary one sits at negative AX y but y > primaryHeight in AppKit.
        let ax = CGRect(x: 0, y: -800, width: 1440, height: 800)
        let appKit = ScreenCoordinates.appKitRect(fromAX: ax, primaryHeight: primaryHeight)
        #expect(appKit.minY == 1000)
        #expect(appKit.maxY == 1800)
    }

    @Test func displayLeftOfPrimaryKeepsNegativeX() {
        let ax = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        #expect(ScreenCoordinates.appKitRect(fromAX: ax, primaryHeight: primaryHeight).minX == -1920)
    }
}
