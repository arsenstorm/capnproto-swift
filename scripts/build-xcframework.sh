#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_ROOT="$ROOT_DIR/.build/xcframework"
ARTIFACTS_DIR="$ROOT_DIR/Artifacts"
XCFRAMEWORK_PATH="$ARTIFACTS_DIR/Capnp.xcframework"

BUILD_TYPE="Release"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--build-type <type>]

Builds a multi-platform Capnp.xcframework (macOS/iOS + simulators).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-type)
      BUILD_TYPE="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage; exit 1 ;;
  esac
done

mkdir -p "$BUILD_ROOT" "$ARTIFACTS_DIR"

build_sdk() {
  local sdk="$1"
  local archs="$2"
  local build_dir="$BUILD_ROOT/$sdk"

  local sdk_path
  sdk_path=$(xcrun --sdk "$sdk" --show-sdk-path)

  cmake -S "$ROOT_DIR" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_OSX_SYSROOT="$sdk_path" \
    -DCMAKE_OSX_ARCHITECTURES="$archs" >&2

  cmake --build "$build_dir" --config "$BUILD_TYPE" >&2

  # Combine static libs into a single archive for the xcframework.
  local lib_out_dir="$build_dir/combined"
  mkdir -p "$lib_out_dir"

  local lib_capnp_c="$build_dir/libcapnp_c.a"
  local lib_capnp="$build_dir/capnproto/c++/src/capnp/libcapnp.a"
  local lib_kj="$build_dir/capnproto/c++/src/kj/libkj.a"

  if [[ ! -f "$lib_capnp_c" ]]; then
    echo "Missing $lib_capnp_c" >&2; exit 1
  fi
  if [[ ! -f "$lib_capnp" ]]; then
    echo "Missing $lib_capnp" >&2; exit 1
  fi
  if [[ ! -f "$lib_kj" ]]; then
    echo "Missing $lib_kj" >&2; exit 1
  fi

  local combined="$lib_out_dir/libCapnp.a"
  libtool -static -o "$combined" "$lib_capnp_c" "$lib_capnp" "$lib_kj"

  echo "$combined"
}

# Build per-platform libraries.
LIB_MACOS=$(build_sdk macosx "arm64;x86_64")
LIB_IOS=$(build_sdk iphoneos "arm64")
LIB_IOSSIM=$(build_sdk iphonesimulator "arm64;x86_64")

# Headers + modulemap for the xcframework.
HEADERS_DIR="$BUILD_ROOT/headers"
rm -rf "$HEADERS_DIR"
mkdir -p "$HEADERS_DIR"
cp "$ROOT_DIR/src/CapnpCLib/include/capnp_c.h" "$HEADERS_DIR/"
cp "$ROOT_DIR/src/CapnpCLib/module.modulemap" "$HEADERS_DIR/"

rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
  -library "$LIB_MACOS" -headers "$HEADERS_DIR" \
  -library "$LIB_IOS" -headers "$HEADERS_DIR" \
  -library "$LIB_IOSSIM" -headers "$HEADERS_DIR" \
  -output "$XCFRAMEWORK_PATH"

echo "Built $XCFRAMEWORK_PATH"
