#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$ROOT_DIR/.build/cmake"
INSTALL_DIR="$ROOT_DIR/src/CapnpCLib"

SDK="macosx"
ARCHS=""
BUILD_TYPE="Release"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--sdk <sdk>] [--archs "<archs>"] [--build-type <type>]

Examples:
  $(basename "$0")
  $(basename "$0") --sdk iphoneos --archs "arm64"
  $(basename "$0") --sdk iphonesimulator --archs "arm64;x86_64"
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sdk)
      SDK="$2"; shift 2 ;;
    --archs)
      ARCHS="$2"; shift 2 ;;
    --build-type)
      BUILD_TYPE="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage; exit 1 ;;
  esac
done

SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)

if [[ -z "$ARCHS" ]]; then
  ARCHS=$(uname -m)
fi

mkdir -p "$BUILD_DIR/$SDK"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR/$SDK" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCHS"

cmake --build "$BUILD_DIR/$SDK" --config "$BUILD_TYPE"
cmake --install "$BUILD_DIR/$SDK" --config "$BUILD_TYPE"

echo "Installed headers and libraries into $INSTALL_DIR"
