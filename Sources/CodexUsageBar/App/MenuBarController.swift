import AppKit
import CodexUsageCore
import Combine
import SwiftUI

@MainActor
final class MenuBarController {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    init(model: AppModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 280)
        popover.contentViewController = NSHostingController(rootView: MenuContentView(model: model, showSettings: { [weak self] in
            self?.showSettings()
        }))

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.imagePosition = .imageOnly
        }
        updateIcon()

        model.coordinator.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateIcon() {
        let state = model.coordinator.state
        let short = state.snapshot?.windows.first(where: { $0.kind == .shortWindow })
        let weekly = state.snapshot?.windows.first(where: { $0.kind == .weekly })

        let iconModel = IconRendererModel(
            shortProgress: short?.usedRatio ?? 0,
            weeklyProgress: weekly?.usedRatio ?? 0,
            isStale: state.isStale
        )
        statusItem.button?.image = IconRenderer().makeImage(for: iconModel)
    }

    private func showSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(model: model)
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "CodexSessions Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 520, height: 360))
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
