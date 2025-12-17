QuickNote - macOS menu bar notes

Minimal native macOS menu-bar app for quick notes. Left-click the status icon to open a popover with a notes dropdown, a plus button to create a new note, and an editor with autosave debounce. Right-click for a context menu (Open window / Close app).

Build & run

- Build: `make`
- Run: `make run`

Behavior

- Notes are stored as separate `.txt` files under `QuickNotes` next to the built binary; names use a human-readable timestamp unless auto-titles are enabled.
- Logs (errors only) are written to `QuickNotesLogs/quicknote.log` next to the binary.
- Status icon: drop `icon.png` next to the binary (Makefile copies it into `build/` on build; lookup is relative to the executable). If not present, a simple pencil icon is drawn in code.
- Settings window (right-click → Settings): toggle debounce saving, auto-title from first sentence, font size, background color.
- Settings persist to `QuickNotesSettings/settings.json` next to the binary.
- Sorting: dropdown follows Settings — creation date (default) or modification date.
- On first launch (no notes), an empty note file is created so the dropdown has a selection.
- Closing the optional "Open" window hides the Dock icon; "Close" fully quits the app.

Tech

- Swift + AppKit, built with `swiftc` via Makefile; no extra dependencies.