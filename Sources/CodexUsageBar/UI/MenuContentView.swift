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

                Text("Updated: \(snapshot.fetchedAt.formatted(date: .omitted, time: .standard))")
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
        let ratio = model.showUsedInsteadOfRemaining ? window.usedRatio : (1 - window.usedRatio)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(window.label)
                    .font(.subheadline)
                Spacer()
                Text(valueText(for: window))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: ratio)
            Text("Reset: \(window.resetAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func valueText(for window: UsageWindow) -> String {
        if model.showUsedInsteadOfRemaining {
            return "\(Int(window.used))/\(Int(window.limit)) used"
        }
        return "\(Int(window.remaining))/\(Int(window.limit)) left"
    }
}
