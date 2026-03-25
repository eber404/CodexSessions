import CodexUsageCore
import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var model: AppModel
    let showSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CodexSessions")
                    .font(.headline)
                Spacer()
                Text(model.activeSourceLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let snapshot = model.coordinator.state.snapshot {
                Text(snapshot.accountEmail ?? "No account email")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(snapshot.windows, id: \.label) { window in
                    windowRow(window)
                }

                Text("Updated: \(updatedLabel(primary: model.lastManualRefreshAt ?? model.coordinator.state.lastRefreshAt, fallback: snapshot.fetchedAt))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(model.coordinator.state.lastError ?? "No usage data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let message = model.authMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Button("Refresh") {
                    model.refreshNow()
                }
                Button("Connect OAuth") {
                    model.connectOAuth()
                }
                Button("Settings") {
                    showSettings()
                }
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    @ViewBuilder
    private func windowRow(_ window: UsageWindow) -> some View {
        let ratio = window.usedRatio
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(window.label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int((window.usedRatio * 100).rounded()))% used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: ratio)
            Text("Reset: \(window.resetAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func updatedLabel(primary: Date?, fallback: Date) -> String {
        let date = primary ?? fallback
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
