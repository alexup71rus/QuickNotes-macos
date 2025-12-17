import Cocoa

final class Settings {
    static let shared = Settings()

    private let fileURL: URL = {
        return DataPaths.settingsFile
    }()

    private struct Payload: Codable {
        var useDebounce: Bool
        var fontSize: Double
        var backgroundHex: String
        var autoTitleFromFirstSentence: Bool
        var sortByModified: Bool
    }

    private var _useDebounce: Bool = true
    private var _fontSize: Double = 14.0
    private var _backgroundColor: NSColor = NSColor.textBackgroundColor
    private var _autoTitleFromFirstSentence: Bool = false
    private var _sortByModified: Bool = false
    private var isLoading = false

    var useDebounce: Bool {
        get { _useDebounce }
        set { update { _useDebounce = newValue } }
    }

    var fontSize: Double {
        get { _fontSize }
        set { update { _fontSize = clampFont(newValue) } }
    }

    var backgroundColor: NSColor {
        get { _backgroundColor }
        set { update { _backgroundColor = newValue } }
    }

    var autoTitleFromFirstSentence: Bool {
        get { _autoTitleFromFirstSentence }
        set { update { _autoTitleFromFirstSentence = newValue } }
    }

    var sortByModified: Bool {
        get { _sortByModified }
        set { update { _sortByModified = newValue } }
    }

    private init() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        isLoading = true
        _useDebounce = payload.useDebounce
        _fontSize = clampFont(payload.fontSize)
        _backgroundColor = Settings.color(fromHex: payload.backgroundHex) ?? NSColor.textBackgroundColor
        _autoTitleFromFirstSentence = payload.autoTitleFromFirstSentence
        _sortByModified = payload.sortByModified
        isLoading = false
    }

    private func persistAndNotify() {
        let payload = Payload(useDebounce: _useDebounce,
                              fontSize: _fontSize,
                              backgroundHex: Settings.hexString(from: _backgroundColor),
                              autoTitleFromFirstSentence: _autoTitleFromFirstSentence,
                              sortByModified: _sortByModified)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: fileURL, options: [.atomic])
        }
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }

    private func update(_ block: () -> Void) {
        block()
        if !isLoading { persistAndNotify() }
    }

    private func clampFont(_ value: Double) -> Double {
        return max(10.0, min(28.0, value))
    }

    private static func hexString(from color: NSColor) -> String {
        let c = color.usingColorSpace(.deviceRGB) ?? color
        let r = Int(round(c.redComponent * 255))
        let g = Int(round(c.greenComponent * 255))
        let b = Int(round(c.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private static func color(fromHex hex: String) -> NSColor? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let val = Int(cleaned, radix: 16) else { return nil }
        let r = CGFloat((val >> 16) & 0xFF) / 255.0
        let g = CGFloat((val >> 8) & 0xFF) / 255.0
        let b = CGFloat(val & 0xFF) / 255.0
        return NSColor(deviceRed: r, green: g, blue: b, alpha: 1.0)
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("SettingsChanged")
}
