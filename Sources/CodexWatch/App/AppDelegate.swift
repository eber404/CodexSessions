import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let appModel = AppModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController(model: appModel)
        appModel.start()
    }
}
