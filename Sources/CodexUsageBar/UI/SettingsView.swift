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

    private static let hoursInDay: ClosedRange<Double> = 0...23

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionBlock(title: "Refresh Interval (minutes)") {
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
                .padding(.horizontal, 2)
                .opacity(0.7)

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
                .padding(.horizontal, 2)
                .opacity(0.7)

            Section {
                Toggle("Enable Session Keep-Alive", isOn: Binding(
                    get: { model.keepAliveEnabled },
                    set: { model.setKeepAliveEnabled($0) }
                ))

                if model.keepAliveEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("First hour of day:")
                            Text(String(format: "%02d:00", model.firstHour))
                                .fontWeight(.semibold)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(model.firstHour) },
                                set: { model.setFirstHour(Int($0)) }
                            ),
                            in: Self.hoursInDay,
                            step: 1
                        )
                        .accessibilityLabel("First hour of day")

                        let blocks = scheduler.calculateTimelineBlocks(firstHour: model.firstHour)
                        SessionTimelineView(blocks: blocks, firstHour: model.firstHour)

                        let nextPing = scheduler.calculateNextPing(firstHour: model.firstHour)
                        Text("Next ping: \(timeFormatter.string(from: nextPing))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Session Keep-Alive")
            }

            Divider()
                .padding(.horizontal, 2)
                .opacity(0.7)

            HStack {
                Spacer(minLength: 0)
                Button("Logout") {
                    onLogout()
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onAppear {
            let minutes = Int(model.refreshIntervalSeconds / 60)
            refreshMinutes = [1, 3, 5].contains(minutes) ? minutes : 5
        }
    }

    @ViewBuilder
    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(.vertical, 12)
    }
}
