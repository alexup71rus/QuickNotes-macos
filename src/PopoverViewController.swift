import Cocoa

class PopoverViewController: NSViewController {
    private var popup: NSPopUpButton!
    private var textView: NSTextView!
    private var titleField: NSTextField!
    private var deleteButton: NSButton!
    private var saveTimer: Timer?
    private var currentNoteURL: URL?
    private var manualTitleEdited = false

    override func loadView() {
        let width: CGFloat = 440
        let height: CGFloat = 340
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        // Popup at top with plus button on the right
        let plusWidth: CGFloat = 26
        let deleteWidth: CGFloat = 26
        let spacing: CGFloat = 10
        let popupWidth = width - (spacing * 2) - plusWidth - 6
        popup = NSPopUpButton(frame: NSRect(x: spacing, y: height - 36, width: popupWidth, height: 26), pullsDown: false)
        popup.target = self
        popup.action = #selector(popupChanged(_:))
        view.addSubview(popup)

        let plusBtn = NSButton(frame: NSRect(x: spacing + popupWidth + 6, y: height - 38, width: plusWidth, height: 28))
        plusBtn.title = "+"
        plusBtn.bezelStyle = .rounded
        plusBtn.target = self
        plusBtn.action = #selector(createNewNoteTapped(_:))
        view.addSubview(plusBtn)

        // Title field with delete button aligned under plus
        let titleY = height - 70
        let titleHeight: CGFloat = 24
        let titleWidth = width - (spacing * 2) - deleteWidth - 6
        titleField = NSTextField(frame: NSRect(x: spacing, y: titleY, width: titleWidth, height: titleHeight))
        titleField.placeholderString = Storage.dateTimeString()
        titleField.delegate = self
        view.addSubview(titleField)

        deleteButton = NSButton(frame: NSRect(x: spacing + titleWidth + 6, y: titleY - 2, width: deleteWidth, height: titleHeight + 4))
        deleteButton.title = "-"
        deleteButton.bezelStyle = .rounded
        deleteButton.target = self
        deleteButton.action = #selector(deleteNoteTapped(_:))
        view.addSubview(deleteButton)

        // Scrollable text area
        let scroll = NSScrollView(frame: NSRect(x: 10, y: 10, width: width - 20, height: height - 90))
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .bezelBorder

        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: scroll.contentSize.width, height: scroll.contentSize.height))
        textView.isRichText = false
        textView.isEditable = true
        textView.delegate = self
        textView.textContainerInset = NSSize(width: 2, height: 2)

        scroll.documentView = textView
        view.addSubview(scroll)

        self.view = view

        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .settingsChanged, object: nil)
        applySettings()

        reloadNotesList(select: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // When popover opens, ensure at least one note exists and open latest
        var urls = Storage.listNotes()
        if urls.isEmpty {
            if let created = try? Storage.createNew("") {
                urls = [created]
            } else {
                Logger.error("Failed to create initial note")
            }
        }

        if let latest = urls.first {
            reloadNotesList(select: latest)
        } else {
            reloadNotesList(select: nil)
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        saveNowIfNeeded()
    }

    private func reloadNotesList(select selectURL: URL?) {
        let urls = Storage.listNotes()
        popup.removeAllItems()
        for u in urls {
            popup.addItem(withTitle: u.lastPathComponent)
        }
        if let sel = selectURL, let idx = popup.indexOfItem(withTitle: sel.lastPathComponent) as Int? {
            currentNoteURL = sel
            textView.string = Storage.read(sel) ?? ""
            let base = sel.deletingPathExtension().lastPathComponent
            if textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                titleField.stringValue = ""
                titleField.placeholderString = base
                manualTitleEdited = false
            } else {
                titleField.stringValue = base
                titleField.placeholderString = base
                manualTitleEdited = false
            }
            popup.selectItem(at: idx)
        } else if let first = urls.first {
            currentNoteURL = first
            textView.string = Storage.read(first) ?? ""
            let base = first.deletingPathExtension().lastPathComponent
            if textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                titleField.stringValue = ""
                titleField.placeholderString = base
                manualTitleEdited = false
            } else {
                titleField.stringValue = base
                titleField.placeholderString = base
                manualTitleEdited = false
            }
            popup.selectItem(at: 0)
        } else {
            currentNoteURL = nil
            textView.string = ""
            titleField.stringValue = ""
            titleField.placeholderString = Storage.dateTimeString()
            manualTitleEdited = false
        }
    }

    @objc private func popupChanged(_ sender: Any?) {
        saveNowIfNeeded()
        guard let sel = popup.selectedItem?.title else { return }
        // Find file by name
        let candidates = Storage.listNotes()
        if let match = candidates.first(where: { $0.lastPathComponent == sel }) {
            currentNoteURL = match
            textView.string = Storage.read(match) ?? ""
            let base = match.deletingPathExtension().lastPathComponent
            if textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                titleField.stringValue = ""
                titleField.placeholderString = base
                manualTitleEdited = false
            } else {
                titleField.stringValue = base
                titleField.placeholderString = base
                manualTitleEdited = false
            }
            // ensure UI reflects saved state from disk
            reloadNotesList(select: match)
        }
    }

    @objc private func createNewNoteTapped(_ sender: Any?) {
        // Create empty new note and select it for editing
        do {
            let newURL = try Storage.createNew("")
            reloadNotesList(select: newURL)
            titleField.stringValue = ""
            titleField.placeholderString = Storage.dateTimeString()
            manualTitleEdited = false
            // focus textView
            view.window?.makeFirstResponder(textView)
        } catch {
            Logger.error("Failed to create new note: \(error.localizedDescription)")
        }
    }

    @objc private func deleteNoteTapped(_ sender: Any?) {
        guard let url = currentNoteURL else { return }
        let alert = NSAlert()
        alert.messageText = "Delete this note?"
        alert.informativeText = "This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            do {
                try FileManager.default.removeItem(at: url)
                manualTitleEdited = false
                reloadNotesList(select: nil)
            } catch {
                Logger.error("Failed to delete note: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleSave() {
        saveTimer?.invalidate()
        if Settings.shared.useDebounce {
            saveTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(flushSave), userInfo: nil, repeats: false)
        } else {
            saveNowIfNeeded()
        }
    }

    private func saveNowIfNeeded() {
        saveTimer?.invalidate()
        flushSave()
    }

    @objc private func flushSave() {
        saveTimer?.invalidate()
        let text = textView.string
        let textTrimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleTrimmed = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        // If both title and body are empty, skip
        if textTrimmed.isEmpty && titleTrimmed.isEmpty {
            return
        }
        do {
            let baseName = desiredBaseName(for: text)
            if let url = currentNoteURL {
                let currentBase = url.deletingPathExtension().lastPathComponent
                var targetURL = url
                if let baseName = baseName, baseName != currentBase {
                    targetURL = try Storage.rename(url, toBaseName: baseName)
                    currentNoteURL = targetURL
                    titleField.stringValue = targetURL.deletingPathExtension().lastPathComponent
                    manualTitleEdited = manualTitleEdited && !titleField.stringValue.isEmpty
                }
                // Avoid touching timestamps if nothing changed
                let existing = Storage.read(targetURL) ?? ""
                if existing != text {
                    try Storage.overwrite(targetURL, text)
                }
            } else {
                let newURL = try Storage.createNew(text, preferredBaseName: baseName)
                currentNoteURL = newURL
                titleField.stringValue = newURL.deletingPathExtension().lastPathComponent
                manualTitleEdited = manualTitleEdited && !titleField.stringValue.isEmpty
                // reload popup and select new file
                reloadNotesList(select: newURL)

                if let idx = popup.indexOfItem(withTitle: newURL.lastPathComponent) as Int? {
                    popup.selectItem(at: idx)
                }
            }
        } catch {
            Logger.error("Failed to save note: \(error.localizedDescription)")
        }
    }

    private func desiredBaseName(for body: String) -> String? {
        let manualTitle = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualTitle.isEmpty {
            return sanitizeTitle(manualTitle)
        }

        if Settings.shared.autoTitleFromFirstSentence {
            if let first = firstSentence(from: body), let sanitized = sanitizeTitle(first) {
                return sanitized
            }
        }

        return nil
    }

    private func firstSentence(from body: String) -> String? {
        let separators = CharacterSet(charactersIn: ".!?\n")
        let comps = body.components(separatedBy: separators)
        guard let first = comps.first else { return nil }
        let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func sanitizeTitle(_ raw: String) -> String? {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>")
        let cleaned = raw.components(separatedBy: invalid).joined()
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return String(trimmed.prefix(80))
    }

    @objc private func settingsChanged() {
        applySettings()
    }

    private func applySettings() {
        textView.font = NSFont.systemFont(ofSize: CGFloat(Settings.shared.fontSize))
        textView.backgroundColor = Settings.shared.backgroundColor
    }
}

extension PopoverViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        scheduleSave()
    }
}

extension PopoverViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSTextField, field === titleField {
            manualTitleEdited = !field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            scheduleSave()
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        if let field = obj.object as? NSTextField, field === titleField {
            saveNowIfNeeded()
        }
    }
}
