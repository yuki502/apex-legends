#!/bin/bash

# Apex Legends Android Build Script
# This script builds the APK from the LÖVE project

set -e

echo "================================"
echo "Apex Legends - Android Build"
echo "================================"

# Check if gradle is available
if ! command -v gradle &> /dev/null; then
    echo "Error: gradle is not installed. Please install Android SDK and gradle."
    exit 1
fi

# Check if LÖVE for Android is set up
if [ ! -d "love-android-sdl2" ]; then
    echo "Cloning LÖVE for Android SDK..."
    git clone https://github.com/love2d/love-android-sdl2.git
fi

# Copy game files to Android project
echo "Copying game assets..."
mkdir -p love-android-sdl2/app/src/main/assets/game
cp -r ../src love-android-sdl2/app/src/main/assets/game/
cp -r ../assets love-android-sdl2/app/src/main/assets/game/
cp -r ../lib love-android-sdl2/app/src/main/assets/game/
cp ../main.lua love-android-sdl2/app/src/main/assets/game/
cp ../conf.lua love-android-sdl2/app/src/main/assets/game/
cp ../LICENSE love-android-sdl2/app/src/main/assets/game/

# Copy build configuration
echo "Configuring build..."
cp build.gradle love-android-sdl2/app/
cp AndroidManifest.xml love-android-sdl2/app/src/main/
cp proguard-rules.pro love-android-sdl2/app/

# Build APK
echo "Building APK..."
cd love-android-sdl2
gradle build

echo ""
echo "================================"
echo "Build Complete!"
echo "APK location: love-android-sdl2/app/build/outputs/apk/release/app-release.apk"
echo "================================"
