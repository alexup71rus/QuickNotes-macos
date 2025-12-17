import Foundation

struct Storage {
    // Directory next to the executable: <exe_dir>/QuickNotesData/QuickNotesContent
    static var notesDirectory: URL {
        return DataPaths.notesDirectory
    }

    static func ensureDir() throws {
        let fm = FileManager.default
        let dir = notesDirectory
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    static func listNotes(sortByModified: Bool = Settings.shared.sortByModified) -> [URL] {
        let fm = FileManager.default
        do {
            try ensureDir()
            let items = try fm.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey], options: [.skipsHiddenFiles])
            let txts = items.filter { $0.pathExtension.lowercased() == "txt" }
            let sorted = txts.sorted { (a, b) -> Bool in
                let ra = try? a.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                let rb = try? b.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                let ca = ra?.creationDate
                let cb = rb?.creationDate
                let ma = ra?.contentModificationDate
                let mb = rb?.contentModificationDate

                if sortByModified {
                    let da = ma ?? ca ?? Date.distantPast
                    let db = mb ?? cb ?? Date.distantPast
                    if da == db { return a.lastPathComponent > b.lastPathComponent }
                    return da > db
                } else {
                    let da = ca ?? Date.distantPast
                    let db = cb ?? Date.distantPast
                    if da == db { return a.lastPathComponent > b.lastPathComponent }
                    return da > db
                }
            }
            return sorted
        } catch {
            Logger.error("Failed to list notes: \(error.localizedDescription)")
            return []
        }
    }

    static func read(_ url: URL) -> String? {
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static func createNew(_ note: String) throws -> URL {
        return try createNew(note, preferredBaseName: nil)
    }

    static func createNew(_ note: String, preferredBaseName: String?) throws -> URL {
        try ensureDir()
        let name = uniqueFileName(base: preferredBaseName ?? dateTimeString())
        let url = notesDirectory.appendingPathComponent(name)
        try note.write(to: url, atomically: true, encoding: .utf8)
        // Ensure creation date is set and stable
        let now = Date()
        try? FileManager.default.setAttributes([.creationDate: now], ofItemAtPath: url.path)
        return url
    }

    static func overwrite(_ url: URL, _ note: String) throws {
        let fm = FileManager.default
        let creation = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? nil
        try note.write(to: url, atomically: false, encoding: .utf8)
        if let creation = creation {
            try? fm.setAttributes([.creationDate: creation], ofItemAtPath: url.path)
        }
    }

    static func rename(_ url: URL, toBaseName base: String) throws -> URL {
        let fm = FileManager.default
        let creation = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? nil
        let targetName = uniqueFileName(base: base)
        let newURL = notesDirectory.appendingPathComponent(targetName)
        try fm.moveItem(at: url, to: newURL)
        if let creation = creation {
            try? fm.setAttributes([.creationDate: creation], ofItemAtPath: newURL.path)
        }
        return newURL
    }

    static func dateTimeString() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "dd-MM-yyyy HH:mm:ss.SSS"
        return fmt.string(from: Date())
    }

    private static func sanitize(base: String) -> String? {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>")
        let cleaned = base.components(separatedBy: invalid).joined()
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return String(trimmed.prefix(80))
    }

    private static func uniqueFileName(base: String) -> String {
        let fm = FileManager.default
        let safeBase = sanitize(base: base) ?? dateTimeString()
        var candidate = safeBase + ".txt"
        var counter = 1
        while fm.fileExists(atPath: notesDirectory.appendingPathComponent(candidate).path) {
            candidate = "\(safeBase)-\(counter).txt"
            counter += 1
        }
        return candidate
    }
}
