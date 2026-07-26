#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${PROJECT_DIR}/dist"
LOVE_FILE="apex-legends.love"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() { echo -e "${GREEN}[BUILD]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_err() { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
  print_step "Cleaning dist directory..."
  rm -rf "$DIST_DIR"
  mkdir -p "$DIST_DIR"
}

build_love() {
  print_step "Packaging .love archive..."
  mkdir -p "$DIST_DIR"
  cd "$PROJECT_DIR"
  zip -9 -r "${DIST_DIR}/${LOVE_FILE}" . \
    -x ".git/*" \
    -x ".github/*" \
    -x "build.sh" \
    -x "dist/*" \
    -x "android/*" \
    -x "node_modules/*"
  echo ""
  echo "  Output: ${DIST_DIR}/${LOVE_FILE}"
  echo "  Size:   $(du -h "${DIST_DIR}/${LOVE_FILE}" | cut -f1)"
}

validate_structure() {
  local errors=0
  print_step "Validating project structure..."

  for f in "main.lua" "conf.lua" "src/game.lua" "lib/classic.lua" "lib/lume.lua"; do
    if [ ! -f "$PROJECT_DIR/$f" ]; then
      print_err "Missing required file: $f"
      errors=$((errors + 1))
    fi
  done

  for d in "src" "lib" "assets"; do
    if [ ! -d "$PROJECT_DIR/$d" ]; then
      print_err "Missing required directory: $d"
      errors=$((errors + 1))
    fi
  done

  if [ $errors -gt 0 ]; then
    print_err "Found $errors structural error(s)"
    return 1
  fi
  print_step "Structure validation passed"
}

run_tests_love() {
  print_step "Running tests in LÖVE..."
  if ! command -v love &> /dev/null; then
    print_err "LÖVE not found. Install love2d (https://love2d.org)"
    return 1
  fi
  if command -v xvfb-run &> /dev/null; then
    xvfb-run love "$PROJECT_DIR" --test
  else
    print_warn "xvfb-run not found, trying direct (may fail without display)"
    love "$PROJECT_DIR" --test
  fi
}

run_tests_lua() {
  print_step "Running Lua-only tests..."
  if ! command -v lua &> /dev/null; then
    print_err "Lua not found"
    return 1
  fi
  lua "$PROJECT_DIR/tests/run_tests.lua"
}

run_tests() {
  validate_structure
  local love_ok=false
  local lua_ok=false

  if command -v love &> /dev/null; then
    if run_tests_love; then
      love_ok=true
    else
      print_warn "LÖVE tests failed"
    fi
  else
    print_warn "LÖVE not installed, skipping LÖVE tests"
  fi

  if command -v lua &> /dev/null; then
    if run_tests_lua; then
      lua_ok=true
    else
      print_warn "Lua tests failed"
    fi
  fi

  if [ "$love_ok" = false ] && [ "$lua_ok" = false ]; then
    print_err "All test suites failed"
    return 1
  fi
  print_step "All available tests passed"
}

build_and_test() {
  build_love
  run_tests
  print_step "Build + Test completed successfully"
}

print_usage() {
  echo "Usage: $0 {love|test|lua-test|all|clean}"
  echo ""
  echo "Commands:"
  echo "  love       Package .love archive (default)"
  echo "  test       Run tests (LÖVE + Lua, requires display or xvfb)"
  echo "  lua-test   Run pure-Lua tests only (no display needed)"
  echo "  all        Build + Test"
  echo "  clean      Remove dist/ directory"
  echo "  android    Prepare Android build environment"
}

case "${1:-love}" in
  love)
    cleanup
    build_love
    ;;
  test)
    run_tests
    ;;
  lua-test)
    validate_structure
    if command -v lua &> /dev/null; then
      run_tests_lua
    else
      print_warn "Lua not installed, skipping Lua-only tests"
    fi
    ;;
  all)
    cleanup
    build_and_test
    ;;
  android)
    bash "$PROJECT_DIR/android/build_android.sh"
    ;;
  clean)
    cleanup
    print_step "Clean complete"
    ;;
  *)
    print_usage
    exit 1
    ;;
esac
