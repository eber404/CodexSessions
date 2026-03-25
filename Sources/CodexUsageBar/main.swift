import AppKit

#if DEBUG
Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle")?.load()
#endif

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()
