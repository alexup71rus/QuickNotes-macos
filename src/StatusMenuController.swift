import Cocoa

class StatusMenuController: NSObject, NSWindowDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let popover = NSPopover()
    let menu = NSMenu()
    var mainWindow: NSWindow?

    override init() {
        super.init()

        if let button = statusItem.button {
            let exeDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
            let iconPath = exeDir.appendingPathComponent("icon.png").path
            var finalImage: NSImage?
            if FileManager.default.fileExists(atPath: iconPath), let img = NSImage(contentsOfFile: iconPath) {
                img.isTemplate = true
                img.size = NSSize(width: 24, height: 24)
                finalImage = img
            } else {
                finalImage = makePencilIcon(size: NSSize(width: 24, height: 24))
            }

            if let image = finalImage {
                image.isTemplate = true
                button.image = image
                button.title = ""
                button.imagePosition = .imageOnly
            }

            popover.contentViewController = PopoverViewController()
            popover.behavior = .transient

            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        }

        let openItem = NSMenuItem(title: "Settings", action: #selector(openWindow(_:)), keyEquivalent: "")
        openItem.target = self
        let quitItem = NSMenuItem(title: "Close", action: #selector(quitApp(_:)), keyEquivalent: "")
        quitItem.target = self

        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
    }

    @objc func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenuUnderButton()
        } else {
            togglePopover()
        }
    }

    func showMenuUnderButton() {
        if let button = statusItem.button {
            let centerX = button.bounds.midX
            let offsetX: CGFloat = 0
            let point = NSPoint(x: centerX + offsetX, y: button.bounds.height)
            menu.popUp(positioning: nil, at: point, in: button)
        }
    }

    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func showMainWindow() {
        DispatchQueue.main.async {
            if let existing = self.mainWindow {
                // If already created, bring to front
                NSApp.activate(ignoringOtherApps: true)
                existing.makeKeyAndOrderFront(nil)
                return
            }

            let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
            let w = NSWindow(contentRect: NSRect(x: screenFrame.midX - 220, y: screenFrame.midY - 140, width: 440, height: 260),
                             styleMask: [.titled, .closable, .resizable],
                             backing: .buffered,
                             defer: false)
            w.title = "QuickNote"
            w.isReleasedWhenClosed = false
            w.delegate = self

            let content = NSView(frame: w.contentView!.bounds)
            content.autoresizingMask = [.width, .height]

            self.buildSettingsUI(into: content)

            w.contentView = content
            self.mainWindow = w

            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide dock icon and window; schedule real close later to avoid CA/animation races
        NSApp.setActivationPolicy(.accessory)
        sender.orderOut(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            sender.close()
            if self.mainWindow === sender {
                self.mainWindow = nil
            }
        }
        return false
    }

    @objc func openWindow(_ sender: Any?) { 
        // Make app regular (show Dock) while window is open
        NSApp.setActivationPolicy(.regular)
        showMainWindow()
    }
    @objc func quitApp(_ sender: Any?) { NSApp.terminate(nil) }

    private func buildSettingsUI(into view: NSView) {
        let padding: CGFloat = 16
        let labelHeight: CGFloat = 18
        let fieldHeight: CGFloat = 22
        let lineSpacing: CGFloat = 10

        var y = view.bounds.height - padding - labelHeight

        let debounce = NSButton(checkboxWithTitle: "Use debounce save (0.8s)", target: self, action: #selector(toggleDebounce(_:)))
        debounce.frame = NSRect(x: padding, y: y, width: view.bounds.width - padding * 2, height: labelHeight)
        debounce.state = Settings.shared.useDebounce ? .on : .off
            debounce.autoresizingMask = [.width]
        view.addSubview(debounce)

        y -= (labelHeight + lineSpacing)

        let autoTitle = NSButton(checkboxWithTitle: "Auto-title from first sentence", target: self, action: #selector(toggleAutoTitle(_:)))
        autoTitle.frame = NSRect(x: padding, y: y, width: view.bounds.width - padding * 2, height: labelHeight)
        autoTitle.state = Settings.shared.autoTitleFromFirstSentence ? .on : .off
            autoTitle.autoresizingMask = [.width]
        view.addSubview(autoTitle)

        y -= (labelHeight + lineSpacing)

        let sortByModified = NSButton(checkboxWithTitle: "Sort notes by modified date", target: self, action: #selector(toggleSortByModified(_:)))
        sortByModified.frame = NSRect(x: padding, y: y, width: view.bounds.width - padding * 2, height: labelHeight)
        sortByModified.state = Settings.shared.sortByModified ? .on : .off
        sortByModified.autoresizingMask = [.width]
        view.addSubview(sortByModified)

        y -= (labelHeight + lineSpacing)

        let fontLabel = NSTextField(labelWithString: "Font size:")
        fontLabel.frame = NSRect(x: padding, y: y, width: 80, height: labelHeight)
            fontLabel.autoresizingMask = [.maxXMargin]
        view.addSubview(fontLabel)

        let fontField = NSTextField(frame: NSRect(x: padding + 90, y: y - 2, width: 60, height: fieldHeight))
        fontField.doubleValue = Settings.shared.fontSize
        fontField.target = self
        fontField.action = #selector(changeFontSize(_:))
            fontField.autoresizingMask = [.maxXMargin]
        view.addSubview(fontField)

        y -= (labelHeight + lineSpacing * 2)

        let colorLabel = NSTextField(labelWithString: "Background color:")
        colorLabel.frame = NSRect(x: padding, y: y, width: 120, height: labelHeight)
            colorLabel.autoresizingMask = [.maxXMargin]
        view.addSubview(colorLabel)

        let colorWell = NSColorWell(frame: NSRect(x: padding + 130, y: y - 4, width: 44, height: 28))
        colorWell.color = Settings.shared.backgroundColor
        colorWell.target = self
        colorWell.action = #selector(changeBackgroundColor(_:))
            colorWell.autoresizingMask = [.maxXMargin]
        view.addSubview(colorWell)
    }

    @objc private func toggleDebounce(_ sender: NSButton) {
        Settings.shared.useDebounce = (sender.state == .on)
    }

    @objc private func toggleAutoTitle(_ sender: NSButton) {
        Settings.shared.autoTitleFromFirstSentence = (sender.state == .on)
    }

    @objc private func toggleSortByModified(_ sender: NSButton) {
        Settings.shared.sortByModified = (sender.state == .on)
    }

    @objc private func changeFontSize(_ sender: NSTextField) {
        Settings.shared.fontSize = sender.doubleValue
    }

    @objc private func changeBackgroundColor(_ sender: NSColorWell) {
        Settings.shared.backgroundColor = sender.color
    }
}

