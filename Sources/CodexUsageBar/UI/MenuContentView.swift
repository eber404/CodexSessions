import CodexUsageCore
import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var coordinator: RefreshCoordinator
    let showSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CodexSessions")
                    .font(.headline)
                Spacer()
                if coordinator.state.snapshot != nil {
                    HStack(spacing: 6) {
                        Text("Updated at \(updatedLabel(primary: model.lastManualRefreshAt ?? coordinator.state.lastRefreshAt, fallback: coordinator.state.snapshot?.fetchedAt))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            model.refreshNow()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Refresh")
                    }
                }
            }

            if let snapshot = coordinator.state.snapshot {
                Text(snapshot.accountEmail ?? "No account email")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(snapshot.windows, id: \.label) { window in
                    windowRow(window)
                }

            } else {
                if shouldShowInitialLoading {
                    loadingStateView
                } else {
                    Text(coordinator.state.lastError ?? "No usage data yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let message = model.authMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 1) {
                if model.isSignedOut {
                    menuActionButton("Signin with OpenAI") {
                        model.connectOAuth()
                    }

                    menuActionButton("Quit") {
                        NSApp.terminate(nil)
                    }
                } else {
                    menuActionButton("Settings") {
                        showSettings()
                    }

                    if shouldShowSignInButton {
                        menuActionButton("Signin with OpenAI") {
                            model.connectOAuth()
                        }
                    }

                    menuActionButton("Quit") {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
        .padding(16)
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

    private func updatedLabel(primary: Date?, fallback: Date?) -> String {
        guard let date = primary ?? fallback else { return "--:--:--" }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private var shouldShowSignInButton: Bool {
        model.isSignedOut || (coordinator.state.snapshot == nil && coordinator.state.lastError != nil)
    }

    private var shouldShowInitialLoading: Bool {
        coordinator.state.snapshot == nil && !model.isSignedOut
    }

    private var loadingStateView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Connecting to OpenAI...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func menuActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        menuActionButton(content: { Text(title) }, action: action)
    }

    @ViewBuilder
    private func menuActionButton<Content: View>(@ViewBuilder content: () -> Content, action: @escaping () -> Void) -> some View {
        HoverMenuRowButton(action: action) {
            content()
        }
    }
}

private struct HoverMenuRowButton<Content: View>: View {
    let action: () -> Void
    let content: Content

    @State private var isHovering = false

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            HStack {
                content
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.12) : Color.clear)
                    .padding(.horizontal, -8)
                    .padding(.vertical, -1)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
