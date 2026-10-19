import AppKit
import Carbon.HIToolbox
import DivGridCore
import SwiftUI

/// Button that records the next key combination. Needs at least one modifier; Esc cancels.
struct HotKeyRecorder: View {
    @State private var isRecording = false
    @State private var label = Preferences.shared.shortcut.displayString
    @State private var monitor: Any?

    var body: some View {
        Button(isRecording ? "Press shortcut…" : label) { isRecording ? stop() : start() }
            .onDisappear { if isRecording { stop() } }
            // The settings window is kept alive when closed, so onDisappear alone isn't reliable.
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
                if isRecording { stop() }
            }
    }

    private func start() {
        isRecording = true
        NotificationCenter.default.post(name: .hotKeyPause, object: nil)
        // Every keypress is swallowed while recording so it doesn't also beep or type into the window.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = Int(event.keyCode)
            let flags = event.modifierFlags
            let characters = event.charactersIgnoringModifiers
            MainActor.assumeIsolated { handle(keyCode: keyCode, flags: flags, characters: characters) }
            return nil
        }
    }

    private func handle(keyCode: Int, flags: NSEvent.ModifierFlags, characters: String?) {
        if keyCode == kVK_Escape {
            stop()
            return
        }
        let modifiers = HotKeyModifiers(flags)
        guard !modifiers.isEmpty else {
            NSSound.beep()
            return
        }
        let shortcut = HotKeyShortcut(
            keyCode: UInt32(keyCode),
            modifiers: modifiers,
            label: HotKeyShortcut.label(forKeyCode: keyCode, characters: characters))
        Preferences.shared.shortcut = shortcut
        label = shortcut.displayString
        stop()
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        NotificationCenter.default.post(name: .hotKeyChanged, object: nil)
    }
}

extension HotKeyModifiers {
    init(_ flags: NSEvent.ModifierFlags) {
        var set: HotKeyModifiers = []
        if flags.contains(.control) { set.insert(.control) }
        if flags.contains(.option) { set.insert(.option) }
        if flags.contains(.shift) { set.insert(.shift) }
        if flags.contains(.command) { set.insert(.command) }
        self = set
    }
}
