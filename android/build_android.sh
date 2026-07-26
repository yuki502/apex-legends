#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${PROJECT_DIR}/dist"
LOVE_FILE="${DIST_DIR}/apex-legends.love"
ANDROID_DIR="${PROJECT_DIR}/android"
WORK_DIR="${ANDROID_DIR}/love-android-sdl2"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() { echo -e "${GREEN}[ANDROID]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_err() { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
  print_step "Cleaning up..."
  rm -rf "$WORK_DIR"
}

check_deps() {
  for cmd in git unzip java; do
    if ! command -v $cmd &> /dev/null; then
      print_err "$cmd not found"
      return 1
    fi
  done
}

clone_love_android() {
  if [ -d "$WORK_DIR" ]; then
    print_step "love-android-sdl2 already cloned"
    return 0
  fi
  print_step "Cloning love-android-sdl2..."
  git clone --depth 1 --branch 2025 https://github.com/love2d/love-android-sdl2.git "$WORK_DIR"
}

copy_game_assets() {
  print_step "Copying game to Android assets..."
  mkdir -p "$WORK_DIR/app/src/main/assets"
  cp "$LOVE_FILE" "$WORK_DIR/app/src/main/assets/game.love"
}

configure_package() {
  print_step "Configuring Android package..."
  local PKG="com.apexlegends.space shooter"
  sed -i "s/applicationId \".*\"/applicationId \"${PKG// /\\.}\"/" "$WORK_DIR/app/build.gradle" 2>/dev/null || true
  sed -i 's/versionName ".*"/versionName "1.0.0"/' "$WORK_DIR/app/build.gradle" 2>/dev/null || true
}

build_apk() {
  print_step "Building APK..."
  cd "$WORK_DIR"
  export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
  if [ -f "./gradlew" ]; then
    chmod +x gradlew
    ./gradlew assembleRelease
  else
    print_err "Gradle wrapper not found in love-android-sdl2"
    return 1
  fi
}

copy_output() {
  print_step "Copying APK to dist/..."
  mkdir -p "$DIST_DIR"
  find "$WORK_DIR" -name "*.apk" -exec cp {} "$DIST_DIR/" \;
  print_step "APK ready in dist/"
}

print_instructions() {
  echo ""
  echo "============================================"
  echo "  Android Build"
  echo "============================================"
  echo ""
  echo "  To set up manually without this script:"
  echo ""
  echo "  1. Clone love-android-sdl2:"
  echo "     git clone https://github.com/love2d/love-android-sdl2.git"
  echo ""
  echo "  2. Place game.love in assets:"
  echo "     cp dist/apex-legends.love love-android-sdl2/app/src/main/assets/game.love"
  echo ""
  echo "  3. Build with Gradle:"
  echo "     cd love-android-sdl2"
  echo "     ./gradlew assembleRelease"
  echo ""
  echo "  4. APK will be at:"
  echo "     love-android-sdl2/app/build/outputs/apk/release/"
  echo ""
  echo "  NOTE: Requires Android SDK. Set ANDROID_HOME env var."
  echo "============================================"
}

main() {
  if [ ! -f "$LOVE_FILE" ]; then
    print_err "Build .love first: ./build.sh love"
    return 1
  fi

  check_deps || return 1
  clone_love_android || return 1
  copy_game_assets || return 1
  configure_package || true

  if command -v java &> /dev/null; then
    build_apk || print_warn "APK build failed (may need Android SDK)"
    copy_output || true
  else
    print_warn "Java not found, skipping APK build"
  fi

  print_instructions
}

main
