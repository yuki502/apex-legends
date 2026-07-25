#!/bin/bash

# Build debug APK

set -e

echo "Building Debug APK..."

if [ ! -d "love-android-sdl2" ]; then
    echo "Cloning LÖVE for Android SDK..."
    git clone https://github.com/love2d/love-android-sdl2.git
fi

# Copy files
mkdir -p love-android-sdl2/app/src/main/assets/game
cp -r ../src love-android-sdl2/app/src/main/assets/game/
cp -r ../assets love-android-sdl2/app/src/main/assets/game/
cp -r ../lib love-android-sdl2/app/src/main/assets/game/
cp ../main.lua love-android-sdl2/app/src/main/assets/game/
cp ../conf.lua love-android-sdl2/app/src/main/assets/game/

cd love-android-sdl2
gradle assembleDebug

echo "Debug APK: love-android-sdl2/app/build/outputs/apk/debug/app-debug.apk"
