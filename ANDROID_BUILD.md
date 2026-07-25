# Android Build Guide for Apex Legends

## Prerequisites

Before building the APK, make sure you have:

1. **Java Development Kit (JDK) 11+**
   ```bash
   java -version
   ```

2. **Android SDK** (API 33 or higher)
   - Download from [Android Studio](https://developer.android.com/studio)
   - Or install via command line tools

3. **Gradle** (7.0 or higher)
   ```bash
   gradle --version
   ```

4. **Git** (for cloning LÖVE for Android)
   ```bash
   git --version
   ```

## Build Options

### Option 1: Using Makefile (Recommended)

```bash
# Initial setup
make setup

# Build debug APK
make build-debug

# Build release APK
make build-release

# Install to device
make install
```

### Option 2: Manual Build

```bash
# Clone LÖVE for Android
cd android
git clone https://github.com/love2d/love-android-sdl2.git

# Copy game files
mkdir -p love-android-sdl2/app/src/main/assets/game
cp -r ../src love-android-sdl2/app/src/main/assets/game/
cp -r ../assets love-android-sdl2/app/src/main/assets/game/
cp -r ../lib love-android-sdl2/app/src/main/assets/game/
cp ../main.lua love-android-sdl2/app/src/main/assets/game/
cp ../conf.lua love-android-sdl2/app/src/main/assets/game/

# Build
cd love-android-sdl2
gradle assembleDebug    # or gradleRelease for release
```

### Option 3: Using Build Scripts

```bash
# Make scripts executable
chmod +x android/build.sh
chmod +x android/build-debug.sh

# Build debug
cd android && bash build-debug.sh

# Build release
cd android && bash build.sh
```

## Output Files

- **Debug APK**: `android/love-android-sdl2/app/build/outputs/apk/debug/app-debug.apk`
- **Release APK**: `android/love-android-sdl2/app/build/outputs/apk/release/app-release.apk`

## Install to Device

```bash
# Make sure device is connected and USB debugging is enabled
adb devices

# Install APK
adb install -r android/love-android-sdl2/app/build/outputs/apk/debug/app-debug.apk

# Or using Makefile
make install
```

## Troubleshooting

### Gradle not found
```bash
# Install gradle using sdkmanager
sdkmanager "build-tools;33.0.0"

# Or set GRADLE_HOME environment variable
export GRADLE_HOME=/path/to/gradle
```

### Build fails with "No toolchain found"
```bash
# Install NDK
sdkmanager "ndk;25.1.8937393"
```

### Permission denied on scripts
```bash
chmod +x android/build.sh
chmod +x android/build-debug.sh
```

### Device not recognized
```bash
# Enable USB debugging on Android device
# Settings > Developer Options > USB Debugging

# Restart adb
adb kill-server
adb start-server
adb devices
```

## Release Build

For a release APK, you need a signing key:

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore apex-legends.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias apex

# Update build.gradle with keystore path and password
# Then build release
cd android/love-android-sdl2
gradle bundleRelease
```

## Project Structure

```
android/
├── build.gradle           # Gradle configuration
├── settings.gradle        # Gradle settings
├── AndroidManifest.xml    # Android manifest
├── proguard-rules.pro     # ProGuard configuration
├── strings.xml            # String resources
├── styles.xml             # Style resources
├── colors.xml             # Color resources
├── build.sh               # Release build script
├── build-debug.sh         # Debug build script
└── love-android-sdl2/     # LÖVE for Android (cloned)
    └── app/src/main/assets/game/  # Game files (auto-copied)
```

## Configuration

### For Different Screen Sizes

The game uses virtual viewport system that adapts to any screen size. No additional configuration needed!

### Performance Tuning

Edit `android/build.gradle` to:
- Change `minSdkVersion` (lower = more devices, but older APIs)
- Enable/disable `useLowMemory` in conf.lua
- Adjust `abiFilters` for supported architectures

## Additional Resources

- [LÖVE for Android Repository](https://github.com/love2d/love-android-sdl2)
- [Android Studio Documentation](https://developer.android.com/docs)
- [Gradle Documentation](https://gradle.org/)
- [Android Publishing Guide](https://developer.android.com/guide/publish)

## Support

For issues with the Android build:
1. Check the troubleshooting section above
2. Review LÖVE Android documentation
3. Check Gradle build output for specific errors
4. File an issue on the repository with build logs
