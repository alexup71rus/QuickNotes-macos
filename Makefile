APP_NAME := QuickNotes
SRC := $(sort $(wildcard src/*.swift))
BUILD_DIR := build
SWIFTC := swiftc
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
APP_ICON_SRC := app-icon.png
TRAY_ICON_SRC := tray-icon.png

.PHONY: default build run debug debug-run clean bundle

default: build


$(BUILD_DIR)/$(APP_NAME): $(SRC) Makefile
	@mkdir -p $(dir $@)
	$(SWIFTC) -o $@ $(SRC) -sdk $(SDK)
	@if [ -f $(TRAY_ICON_SRC) ]; then mkdir -p $(BUILD_DIR)/QuickNotesData/Assets && cp -f $(TRAY_ICON_SRC) $(BUILD_DIR)/QuickNotesData/Assets/tray-icon.png; fi
	@if [ -f icon.png ]; then mkdir -p $(BUILD_DIR)/QuickNotesData/Assets && cp -f icon.png $(BUILD_DIR)/QuickNotesData/Assets/icon.png; fi
	@if [ -f $(APP_ICON_SRC) ]; then mkdir -p $(BUILD_DIR)/QuickNotesData/Assets && cp -f $(APP_ICON_SRC) $(BUILD_DIR)/QuickNotesData/Assets/app-icon.png; fi

$(BUILD_DIR)/$(APP_NAME)-debug: $(SRC) Makefile
	@mkdir -p $(dir $@)
	$(SWIFTC) -DDEBUG -o $@ $(SRC) -sdk $(SDK)
	@if [ -f $(TRAY_ICON_SRC) ]; then mkdir -p $(BUILD_DIR)/QuickNotesData/Assets && cp -f $(TRAY_ICON_SRC) $(BUILD_DIR)/QuickNotesData/Assets/tray-icon.png; fi
	@if [ -f icon.png ]; then mkdir -p $(BUILD_DIR)/QuickNotesData/Assets && cp -f icon.png $(BUILD_DIR)/QuickNotesData/Assets/icon.png; fi
	@if [ -f $(APP_ICON_SRC) ]; then mkdir -p $(BUILD_DIR)/QuickNotesData/Assets && cp -f $(APP_ICON_SRC) $(BUILD_DIR)/QuickNotesData/Assets/app-icon.png; fi

bundle: build
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(APP_NAME) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@if [ -f $(TRAY_ICON_SRC) ]; then cp -f $(TRAY_ICON_SRC) $(BUNDLE)/Contents/Resources/tray-icon.png; fi
	@if [ -f $(APP_ICON_SRC) ]; then cp -f $(APP_ICON_SRC) $(BUNDLE)/Contents/Resources/app-icon.png; fi
	@if [ -f icon.png ]; then cp -f icon.png $(BUNDLE)/Contents/Resources/icon.png; fi
	@ICON_SRC=""; \
	if [ -f $(APP_ICON_SRC) ]; then ICON_SRC=$(APP_ICON_SRC); \
	elif [ -f $(TRAY_ICON_SRC) ]; then ICON_SRC=$(TRAY_ICON_SRC); \
	elif [ -f icon.png ]; then ICON_SRC=icon.png; fi; \
	if [ "$$ICON_SRC" != "" ]; then \
		rm -rf $(BUILD_DIR)/AppIcon.iconset; \
		mkdir -p $(BUILD_DIR)/AppIcon.iconset; \
		for sz in 16 32 64 128 256 512; do \
			sips -z $$sz $$sz $$ICON_SRC --out $(BUILD_DIR)/AppIcon.iconset/icon_$$szx$$sz.png >/dev/null; \
			sips -z $$((sz*2)) $$((sz*2)) $$ICON_SRC --out $(BUILD_DIR)/AppIcon.iconset/icon_$$szx$$sz@2x.png >/dev/null; \
		 done; \
		iconutil -c icns $(BUILD_DIR)/AppIcon.iconset -o $(BUNDLE)/Contents/Resources/AppIcon.icns; \
	else \
		echo "[warn] No app icon source found (app-icon.png / tray-icon.png / icon.png). Bundle will use default."; \
	fi
	@printf '%s\n' \
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>" \
"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" \
"<plist version=\"1.0\">" \
"<dict>" \
"    <key>CFBundleDevelopmentRegion</key>" \
"    <string>en</string>" \
"    <key>CFBundleExecutable</key>" \
"    <string>$(APP_NAME)</string>" \
"    <key>CFBundleIdentifier</key>" \
"    <string>com.example.quicknotes</string>" \
"    <key>CFBundleInfoDictionaryVersion</key>" \
"    <string>6.0</string>" \
"    <key>CFBundleName</key>" \
"    <string>$(APP_NAME)</string>" \
"    <key>CFBundlePackageType</key>" \
"    <string>APPL</string>" \
"    <key>CFBundleShortVersionString</key>" \
"    <string>1.0</string>" \
"    <key>CFBundleVersion</key>" \
"    <string>1</string>" \
"    <key>LSMinimumSystemVersion</key>" \
"    <string>11.0</string>" \
"    <key>NSHighResolutionCapable</key>" \
"    <true/>" \
"    <key>CFBundleIconFile</key>" \
"    <string>AppIcon</string>" \
"</dict>" \
"</plist>" > $(BUNDLE)/Contents/Info.plist
	@echo "Bundle created at $(BUNDLE)"

build: $(BUILD_DIR)/$(APP_NAME)

debug: $(BUILD_DIR)/$(APP_NAME)-debug

run: build
	$(BUILD_DIR)/$(APP_NAME)

debug-run: debug
	$(BUILD_DIR)/$(APP_NAME)-debug

clean:
	rm -rf $(BUILD_DIR)
