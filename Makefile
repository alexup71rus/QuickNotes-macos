APP_NAME := QuickNote
SRC := $(sort $(wildcard src/*.swift))
BUILD_DIR := build
SWIFTC := swiftc
SDK := $(shell xcrun --sdk macosx --show-sdk-path)

.PHONY: default build run debug debug-run clean

default: build

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/$(APP_NAME): $(SRC) Makefile | $(BUILD_DIR)
	$(SWIFTC) -o $@ $(SRC) -sdk $(SDK)

$(BUILD_DIR)/$(APP_NAME)-debug: $(SRC) Makefile | $(BUILD_DIR)
	$(SWIFTC) -DDEBUG -o $@ $(SRC) -sdk $(SDK)

build: $(BUILD_DIR)/$(APP_NAME)

debug: $(BUILD_DIR)/$(APP_NAME)-debug

run: build
	$(BUILD_DIR)/$(APP_NAME)

debug-run: debug
	$(BUILD_DIR)/$(APP_NAME)-debug

clean:
	rm -rf $(BUILD_DIR)
