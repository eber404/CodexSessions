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
    private var loadingAnimationTimer: Timer?
    private var loadingRotationDegrees: Double = 0

    init(model: AppModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 280)
        popover.contentViewController = NSHostingController(rootView: MenuContentView(model: model, coordinator: model.coordinator, showSettings: { [weak self] in
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
            .sink { [weak self] state in
                self?.syncLoadingAnimation(isLoading: state.isLoading)
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showMainPopover()
        }
    }

    private func showMainPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        popover.contentViewController?.view.window?.makeKey()
    }

    private func updateIcon() {
        let state = model.coordinator.state
        let short = state.snapshot?.windows.first(where: { $0.kind == .shortWindow })
        let weekly = state.snapshot?.windows.first(where: { $0.kind == .weekly })

        let iconModel = IconRendererModel(
            shortProgress: short?.usedRatio ?? 0,
            weeklyProgress: weekly?.usedRatio ?? 0,
            isStale: state.isStale,
            isLoading: state.isLoading,
            rotationDegrees: loadingRotationDegrees
        )
        statusItem.button?.image = IconRenderer().makeImage(for: iconModel)
    }

    private func syncLoadingAnimation(isLoading: Bool) {
        guard isLoading else {
            loadingAnimationTimer?.invalidate()
            loadingAnimationTimer = nil
            loadingRotationDegrees = 0
            return
        }

        guard loadingAnimationTimer == nil else { return }
        loadingAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.loadingRotationDegrees -= 18
            if self.loadingRotationDegrees <= -360 {
                self.loadingRotationDegrees += 360
            }
            self.updateIcon()
        }
        loadingAnimationTimer?.tolerance = 0.02
        if let loadingAnimationTimer {
            RunLoop.main.add(loadingAnimationTimer, forMode: .common)
        }
    }

    private func showSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(model: model, onLogout: { [weak self] in
            self?.logoutFromSettings()
        })
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "CodexSessions Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 380, height: 440))
        window.minSize = NSSize(width: 380, height: 440)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    private func logoutFromSettings() {
        model.logout()
        settingsWindow?.close()
        settingsWindow = nil
        showMainPopover()
    }
}
