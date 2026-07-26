# Android Build

This directory contains the configuration for building Apex Legends as an Android APK using LÖVE's official Android backend ([love-android-sdl2](https://github.com/love2d/love-android-sdl2)).

## Structure

```
android/
├── README.md              This file
└── build_android.sh       Helper script for Android builds
```

No permanent Android files are stored here. The build script downloads love-android-sdl2 on demand.

## How it works

LÖVE for Android uses the `love-android-sdl2` Gradle project. The game `.love` archive is placed in `app/src/main/assets/game.love`, and Gradle builds it into an APK with the LÖVE runtime embedded.

## Prerequisites

- Java 17 (JDK)
- Android SDK (set `ANDROID_HOME` environment variable)
- Linux or macOS (Windows via WSL)

## Build commands

```bash
# Build .love first
./build.sh love

# Build Android APK
./build.sh android
```

Output APK will be in `dist/`.

## Manual build

```bash
# Clone love-android-sdl2
git clone --depth 1 --branch 2025 https://github.com/love2d/love-android-sdl2.git

# Copy game
cp dist/apex-legends.love love-android-sdl2/app/src/main/assets/game.love

# Build
cd love-android-sdl2
export ANDROID_HOME=/path/to/android-sdk
./gradlew assembleRelease

# APK at: love-android-sdl2/app/build/outputs/apk/release/
```

## Notes

- `conf.lua` already has `t.externalstorage = true` for Android save compatibility.
- `t.identity = "apex-legends"` ensures save files go to a consistent location.
- The window configuration in `conf.lua` is ignored on Android (LÖVE uses fullscreen).
