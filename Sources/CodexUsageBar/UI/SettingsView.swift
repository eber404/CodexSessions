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

                    HStack(spacing: 16) {
                        Picker("Hour", selection: Binding(
                            get: { model.firstHour },
                            set: { model.setFirstHour($0) }
                        )) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .labelsHidden()

                        Picker("Minute", selection: Binding(
                            get: { model.firstMinute },
                            set: { model.setFirstMinute($0) }
                        )) {
                            Text("00").tag(0)
                            Text("15").tag(15)
                            Text("30").tag(30)
                            Text("45").tag(45)
                        }
                        .labelsHidden()
                    }

                    let blocks = scheduler.calculateTimelineBlocksWithMinutes(
                        firstHour: model.firstHour,
                        firstMinute: model.firstMinute
                    )
                    SessionTimelineViewWithMinutes(
                        blocks: blocks,
                        firstHour: model.firstHour,
                        firstMinute: model.firstMinute
                    )

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
