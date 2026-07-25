.PHONY: help build-debug build-release clean install setup

help:
	@echo "Apex Legends - Build Targets"
	@echo ""
	@echo "Targets:"
	@echo "  setup          - Clone and setup LÖVE for Android"
	@echo "  build-debug    - Build debug APK"
	@echo "  build-release  - Build release APK"
	@echo "  install        - Install APK to connected device"
	@echo "  clean          - Clean build artifacts"


setup:
	@echo "Setting up LÖVE for Android..."
	cd android && chmod +x build.sh build-debug.sh
	git clone https://github.com/love2d/love-android-sdl2.git android/love-android-sdl2


build-debug:
	@echo "Building debug APK..."
	cd android && bash build-debug.sh


build-release:
	@echo "Building release APK..."
	cd android && bash build.sh


install:
	@echo "Installing APK to device..."
	adb install -r android/love-android-sdl2/app/build/outputs/apk/debug/app-debug.apk


clean:
	@echo "Cleaning build artifacts..."
	cd android && rm -rf love-android-sdl2/app/build
