import ServiceManagement

struct LoginItemManager {
    var isEnabled: Bool {
        false
    }

    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Best effort in a package executable context.
            }
        }
    }
}
