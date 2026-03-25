import AppKit

#if DEBUG
private func loadInjectionBundleIfAppIsRunning() {
    let isInjectionRunning = !NSRunningApplication.runningApplications(
        withBundleIdentifier: "com.johnholdsworth.InjectionIII"
    ).isEmpty

    guard isInjectionRunning else { return }
    Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle")?.load()
}

loadInjectionBundleIfAppIsRunning()
#endif

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()
