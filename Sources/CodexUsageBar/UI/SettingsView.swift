import SwiftUI
import CodexUsageCore

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let onLogout: () -> Void
    @State private var refreshMinutes: Int = 5
    @State private var scheduler = SessionScheduler()
    @State private var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionBlock(title: "Refresh Interval") {
                Picker("", selection: $refreshMinutes) {
                    Text("1 min").tag(1)
                    Text("3 min").tag(3)
                    Text("5 min").tag(5)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: refreshMinutes) { _, newValue in
                    model.setRefreshInterval(minutes: newValue)
                }
            }

            Divider()

            sectionBlock(title: "System") {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLoginEnabled($0) }
                    )
                )
            }

            Divider()

            sectionBlock(title: "Session Keep-Alive") {
                Toggle("Enable Session Keep-Alive", isOn: Binding(
                    get: { model.keepAliveEnabled },
                    set: { model.setKeepAliveEnabled($0) }
                ))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("First ping at:")
                        Spacer()
                        Text(String(format: "%02d:%02d", model.firstHour, model.firstMinute))
                            .fontWeight(.semibold)
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text("Hour")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(
                                value: Binding(
                                    get: { Double(model.firstHour) },
                                    set: { model.setFirstHour(Int($0)) }
                                ),
                                in: 0...23,
                                step: 1
                            )
                            .accessibilityLabel("Hour picker")
                        }

                        HStack {
                            Text("Minute")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(
                                value: Binding(
                                    get: { Double(model.firstMinute) },
                                    set: { model.setFirstMinute(Int($0)) }
                                ),
                                in: 0...55,
                                step: 5
                            )
                            .accessibilityLabel("Minute picker")
                        }
                    }

                    let blocks = scheduler.calculateSessionBlocks(
                        firstHour: model.firstHour,
                        firstMinute: model.firstMinute
                    )
                    SessionTimelineViewWithMinutes(sessionBlocks: blocks)

                    if model.keepAliveEnabled {
                        let nextPing = scheduler.calculateNextPing(
                            firstHour: model.firstHour,
                            firstMinute: model.firstMinute
                        )
                        Text("Next ping: \(timeFormatter.string(from: nextPing))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Keep-alive is off. Enable it to start automatic pings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("Logout") {
                    onLogout()
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .padding(16)
        .frame(width: 360)
        .onAppear {
            let minutes = Int(model.refreshIntervalSeconds / 60)
            refreshMinutes = [1, 3, 5].contains(minutes) ? minutes : 5
        }
    }

    @ViewBuilder
    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }
}
