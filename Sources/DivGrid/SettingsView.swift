import DivGridCore
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(PreferenceKey.columns) private var columns = GridSize.default.columns
    @AppStorage(PreferenceKey.rows) private var rows = GridSize.default.rows
    @AppStorage(PreferenceKey.margin) private var margin = 0.0

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    private var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
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
                Stepper("Columns: \(columns)", value: $columns, in: GridSize.allowedRange)
                Stepper("Rows: \(rows)", value: $rows, in: GridSize.allowedRange)
                LabeledContent("Margin") {
                    HStack {
                        Slider(value: $margin, in: Preferences.marginRange, step: 1)
                        Text("\(Int(margin)) pt").monospacedDigit().frame(width: 44, alignment: .trailing)
                    }
                }
                .help("Gap kept inside each window's region, so neighbouring windows sit twice this far apart.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 400)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            Log.lifecycle.error("Launch at login change failed: \(error, privacy: .public)")
            loginError = error.localizedDescription
        }
        // Show the real state, e.g. when registration failed or still needs approval.
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
