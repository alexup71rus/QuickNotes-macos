import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        for w in NSApp.windows { w.orderOut(nil) }
        // Default to accessory so app sits in menu bar only
        NSApp.setActivationPolicy(.accessory)
        if let iconURL = DataPaths.appIconFile, let img = NSImage(contentsOf: iconURL) {
            img.isTemplate = false
            NSApp.applicationIconImage = img
        }
        statusController = StatusMenuController()
    }
}
