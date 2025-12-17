import Foundation

struct DataPaths {
    private static var baseDirectory: URL {
        let exe = URL(fileURLWithPath: CommandLine.arguments[0])
        let exeDir = exe.deletingLastPathComponent()

        // If running from a .app bundle, place data next to the bundle (sibling), not inside Contents/MacOS
        let contentsDir = exeDir.deletingLastPathComponent() // .../Contents
        let appBundle = contentsDir.deletingLastPathComponent() // .../QuickNotes.app
        if appBundle.pathExtension == "app" {
            let baseRoot = appBundle.deletingLastPathComponent() // parent of .app
            let base = baseRoot.appendingPathComponent("QuickNotesData", isDirectory: true)
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true, attributes: nil)
            return base
        }

        let base = exeDir.appendingPathComponent("QuickNotesData", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true, attributes: nil)
        return base
    }

    private static var bundleResources: URL? {
        return Bundle.main.resourceURL
    }

    static var trayIconFile: URL? {
        let fm = FileManager.default
        let basePreferred = baseDirectory.appendingPathComponent("Assets/tray-icon.png")
        if fm.fileExists(atPath: basePreferred.path) { return basePreferred }

        let baseFallback = baseDirectory.appendingPathComponent("Assets/icon.png")
        if fm.fileExists(atPath: baseFallback.path) { return baseFallback }

        if let res = bundleResources {
            let bundlePreferred = res.appendingPathComponent("tray-icon.png")
            if fm.fileExists(atPath: bundlePreferred.path) { return bundlePreferred }
            let bundleFallback = res.appendingPathComponent("icon.png")
            if fm.fileExists(atPath: bundleFallback.path) { return bundleFallback }
        }

        let exeDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        let local = exeDir.appendingPathComponent("icon.png")
        if fm.fileExists(atPath: local.path) { return local }

        return nil
    }

    static var appIconFile: URL? {
        let fm = FileManager.default
        let basePreferred = baseDirectory.appendingPathComponent("Assets/app-icon.png")
        if fm.fileExists(atPath: basePreferred.path) { return basePreferred }

        let baseFallback = baseDirectory.appendingPathComponent("Assets/icon.png")
        if fm.fileExists(atPath: baseFallback.path) { return baseFallback }

        if let res = bundleResources {
            let bundlePreferred = res.appendingPathComponent("app-icon.png")
            if fm.fileExists(atPath: bundlePreferred.path) { return bundlePreferred }
            let bundleFallback = res.appendingPathComponent("icon.png")
            if fm.fileExists(atPath: bundleFallback.path) { return bundleFallback }
        }

        return trayIconFile
    }

    static var notesDirectory: URL {
        let dir = baseDirectory.appendingPathComponent("QuickNotesContent", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    static var settingsFile: URL {
        let dir = baseDirectory.appendingPathComponent("Settings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir.appendingPathComponent("settings.json")
    }

    static var logsDirectory: URL {
        let dir = baseDirectory.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }
}
