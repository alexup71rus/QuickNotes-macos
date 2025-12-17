import Foundation

struct Logger {
    private static var logDirectory: URL {
        return DataPaths.logsDirectory
    }

    private static var logFileURL: URL {
        return logDirectory.appendingPathComponent("quicknotes.log")
    }

    private static func ensureDir() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: logDirectory.path) {
            try? fm.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    static func write(_ level: String, _ message: String) {
        ensureDir()
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(level): \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let fh = try? FileHandle(forWritingTo: logFileURL) {
                fh.seekToEndOfFile()
                fh.write(data)
                try? fh.close()
                return
            }
        }

        try? data.write(to: logFileURL)
    }

    static func error(_ message: String) {
        write("ERROR", message)
    }
}
