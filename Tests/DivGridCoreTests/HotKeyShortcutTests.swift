import Carbon.HIToolbox
import Testing

@testable import DivGridCore

@Suite struct HotKeyShortcutTests {
    @Test func carbonMaskRoundTrip() {
        let all: HotKeyModifiers = [.control, .option, .shift, .command]
        #expect(HotKeyModifiers(carbonMask: all.carbonMask) == all)
        #expect(HotKeyModifiers(carbonMask: 0).isEmpty)
    }

    @Test func carbonMaskMatchesCarbonConstants() {
        let mods: HotKeyModifiers = [.control, .option]
        #expect(mods.carbonMask == UInt32(controlKey | optionKey))
    }

    @Test func symbolsUseMacOSOrder() {
        #expect(HotKeyModifiers([.command, .shift, .option, .control]).symbols == "⌃⌥⇧⌘")
    }

    @Test func defaultShortcutDisplay() {
        #expect(HotKeyShortcut.default.displayString == "⌃⌥Space")
    }

    @Test func specialKeysUseSymbols() {
        #expect(HotKeyShortcut.label(forKeyCode: kVK_LeftArrow, characters: "\u{F702}") == "←")
        #expect(HotKeyShortcut.label(forKeyCode: kVK_F5, characters: nil) == "F5")
    }

    @Test func letterKeysUseUppercasedCharacters() {
        #expect(HotKeyShortcut.label(forKeyCode: kVK_ANSI_G, characters: "g") == "G")
    }

    @Test func unknownKeyFallsBackToCode() {
        #expect(HotKeyShortcut.label(forKeyCode: 200, characters: nil) == "Key 200")
    }
}
