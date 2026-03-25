import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var manualToken: String = ""
    @State private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section("Auth") {
                TextField("Preferred auth.json path (optional)", text: $model.preferredAuthPath)
                HStack {
                    Button("Apply Source") {
                        model.rebuildServiceAndRefresh()
                    }
                    Button("Connect with OpenAI (Codex-compatible)") {
                        model.connectOAuth()
                    }
                    Button("Disconnect OAuth") {
                        model.disconnectOAuth()
                    }
                }

                SecureField("Manual access token", text: $manualToken)
                Button("Save Manual Token") {
                    guard !manualToken.isEmpty else { return }
                    model.saveManualToken(manualToken)
                    manualToken = ""
                }
            }

            Section("Display") {
                Toggle("Show usage as used", isOn: $model.showUsedInsteadOfRemaining)
            }

            Section("Refresh") {
                HStack {
                    Text("Interval (seconds)")
                    Slider(value: $model.refreshIntervalSeconds, in: 60 ... 900, step: 60)
                    Text("\(Int(model.refreshIntervalSeconds))")
                        .monospacedDigit()
                }
                Button("Apply Interval") {
                    model.updateRefreshInterval()
                }
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LoginItemManager().setEnabled(enabled)
                    }
            }
        }
        .padding()
        .onAppear {
            launchAtLogin = LoginItemManager().isEnabled
        }
    }
}
