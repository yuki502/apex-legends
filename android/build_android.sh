#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${PROJECT_DIR}/dist"
LOVE_FILE="${DIST_DIR}/apex-legends.love"
ANDROID_DIR="${PROJECT_DIR}/android"
WORK_DIR="${ANDROID_DIR}/love-android"

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
    print_step "love-android already cloned"
    return 0
  fi
  print_step "Cloning love-android with submodules..."
  git clone --depth 1 --recurse-submodules --shallow-submodules --branch main https://github.com/love2d/love-android.git "$WORK_DIR"
  rm -rf "$WORK_DIR/.git"
}

copy_game_assets() {
  print_step "Copying game to Android assets..."
  mkdir -p "$WORK_DIR/app/src/embed/assets"
  cp "$LOVE_FILE" "$WORK_DIR/app/src/embed/assets/game.love"
}

configure_project() {
  print_step "Configuring Android project..."
  cat > "$WORK_DIR/gradle.properties" << 'PROPERTIES'
app.name=Apex Legends
app.application_id=com.apexlegends.spaceshooter
app.orientation=landscape
app.version_code=1
app.version_name=1.0.0
android.enableJetifier=false
android.useAndroidX=true
android.nonTransitiveRClass=true
android.nonFinalResIds=true
android.dependency.useConstraints=true
PROPERTIES
}

build_apk() {
  print_step "Building APK..."
  cd "$WORK_DIR"
  export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
  if [ -f "./gradlew" ]; then
    chmod +x gradlew
    ./gradlew assembleEmbedNoRecordDebug assembleEmbedNoRecordRelease 2>&1 | tee build.log
  else
    print_err "Gradle wrapper not found in love-android"
    return 1
  fi
}

copy_output() {
  print_step "Copying APKs to dist/..."
  mkdir -p "$DIST_DIR"
  find "$WORK_DIR" -name "*.apk" -exec cp {} "$DIST_DIR/" \;
  print_step "APKs ready in dist/:"
  ls -la "$DIST_DIR"/*.apk 2>/dev/null || print_warn "No APK files found"
}

main() {
  if [ ! -f "$LOVE_FILE" ]; then
    print_err "Build .love first: ./build.sh love"
    return 1
  fi

  check_deps || return 1
  clone_love_android || return 1
  copy_game_assets || return 1
  configure_project || return 1

  build_apk || return 1
  copy_output || true
}

main
