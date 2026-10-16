import AppKit
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    // Same UserDefaults keys as `Settings`.
    @AppStorage("columns") private var columns = 6
    @AppStorage("rows") private var rows = 6
    @AppStorage("margin") private var margin = 0.0

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    private var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in setLaunchAtLogin(on) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                } else if needsApproval {
                    Text("Approve DivGrid in System Settings → General → Login Items.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Shortcut") {
                LabeledContent("Show grid") { HotKeyRecorder() }
            }
            Section("Grid") {
                Stepper("Columns: \(columns)", value: $columns, in: 2...20)
                Stepper("Rows: \(rows)", value: $rows, in: 2...20)
                LabeledContent("Margin") {
                    HStack {
                        Slider(value: $margin, in: 0...20, step: 1)
                        Text("\(Int(margin)) pt").monospacedDigit().frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 400)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
        }
        // Reflect the real state (e.g. registration failed or needs approval).
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

/// Button that records the next key combination (requires at least one modifier; Esc cancels).
struct HotKeyRecorder: View {
    @State private var recording = false
    @State private var label = Settings.hotKeyDescription
    @State private var monitor: Any?

    var body: some View {
        Button(recording ? "Press shortcut…" : label) { recording ? stop() : start() }
            .onDisappear { if recording { stop() } }
    }

    private func start() {
        recording = true
        NotificationCenter.default.post(name: .hotKeyPause, object: nil)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
            if Int(e.keyCode) == kVK_Escape { stop(); return nil }
            let mods = Settings.carbonModifiers(e.modifierFlags)
            guard mods != 0 else { NSSound.beep(); return nil }
            Settings.hotKeyCode = UInt32(e.keyCode)
            Settings.hotKeyModifiers = mods
            Settings.hotKeyLabel = Settings.keyLabel(for: e)
            label = Settings.hotKeyDescription
            stop()
            return nil
        }
    }

    private func stop() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        recording = false
        NotificationCenter.default.post(name: .hotKeyChanged, object: nil)
    }
}
