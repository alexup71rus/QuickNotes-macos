import Foundation

enum AutoLaunchManager {
    private static let label = "com.example.quicknotes"

    private static var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func isEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    static func setEnabled(_ enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }

    private static func enable() {
        let fm = FileManager.default
        let url = launchAgentURL
        do {
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let exe = currentExecutable()
            let plist: [String: Any] = [
                "Label": label,
                "ProgramArguments": [exe.path],
                "RunAtLoad": true,
                "KeepAlive": false,
                "ProcessType": "Background"
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: url, options: [.atomic])
        } catch {
            Logger.error("Failed to enable launch at login: \(error.localizedDescription)")
        }
    }

    private static func disable() {
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: launchAgentURL.path) {
                try fm.removeItem(at: launchAgentURL)
            }
        } catch {
            Logger.error("Failed to disable launch at login: \(error.localizedDescription)")
        }
    }

    private static func currentExecutable() -> URL {
        let exe = URL(fileURLWithPath: CommandLine.arguments[0])
        return exe.standardizedFileURL
    }
}
