import Carbon.HIToolbox
import DivGridCore

/// A system-wide hotkey registered through Carbon (needs no extra permissions). Unregisters on deinit.
@MainActor
final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(shortcut: HotKeyShortcut, action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
                // Carbon delivers application events on the main thread.
                MainActor.assumeIsolated { hotKey.action() }
                return noErr
            }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        guard installStatus == noErr else {
            Log.hotKey.error("InstallEventHandler failed: \(installStatus)")
            return
        }

        let registerStatus = RegisterEventHotKey(
            shortcut.keyCode, shortcut.modifiers.carbonMask,
            EventHotKeyID(signature: OSType(0x4447_5244), id: 1),  // 'DGRD'
            GetApplicationEventTarget(), 0, &hotKeyRef)
        if registerStatus == noErr {
            Log.hotKey.info("Registered \(shortcut.displayString, privacy: .public)")
        } else {
            // Typically eventHotKeyExistsErr: another app already owns this combination.
            Log.hotKey.error(
                "Could not register \(shortcut.displayString, privacy: .public): OSStatus \(registerStatus)")
        }
    }

    isolated deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
