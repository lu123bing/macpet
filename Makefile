.PHONY: build run clean app

# Swift 构建路径
SWIFT_BUILD_DIR = MacPet/.build
APP_NAME = MacPet
APP_DIR = build/$(APP_NAME).app

build:
	cd MacPet && swift build

release:
	cd MacPet && swift build -c release --arch x86_64 --arch arm64

run:
	cd MacPet && swift run

app: release
	mkdir -p $(APP_DIR)/Contents/MacOS
	mkdir -p $(APP_DIR)/Contents/Resources
	cp $(SWIFT_BUILD_DIR)/apple/Products/Release/$(APP_NAME) $(APP_DIR)/Contents/MacOS/
	@if [ -d "MacPet/Sources/MacPet/Resources/Animations" ]; then \
		cp -r MacPet/Sources/MacPet/Resources/Animations $(APP_DIR)/Contents/Resources/; \
	fi
	cp MacPet/Info.plist $(APP_DIR)/Contents/ 2>/dev/null || true
	@echo "✅ App built at $(APP_DIR)"

clean:
	cd MacPet && swift package clean
	rm -rf build

xcode:
	cd MacPet && swift package generate-xcodeproj
