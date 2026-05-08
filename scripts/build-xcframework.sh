#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_ROOT="$ROOT_DIR/.build/xcframework"
ARTIFACTS_DIR="$ROOT_DIR/Artifacts"
XCFRAMEWORK_PATH="$ARTIFACTS_DIR/Capnp.xcframework"

BUILD_TYPE="Release"
MACOSX_DEPLOYMENT_TARGET="12.0"
IOS_DEPLOYMENT_TARGET="16.0"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--build-type <type>] [--macosx-target <version>] [--ios-target <version>]

Builds a multi-platform Capnp.xcframework (macOS/iOS + simulators).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-type)
      BUILD_TYPE="$2"; shift 2 ;;
    --macosx-target)
      MACOSX_DEPLOYMENT_TARGET="$2"; shift 2 ;;
    --ios-target)
      IOS_DEPLOYMENT_TARGET="$2"; shift 2 ;;
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

  local deployment_target=""
  if [[ "$sdk" == "macosx" ]]; then
    deployment_target="-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}"
  else
    deployment_target="-DCMAKE_OSX_DEPLOYMENT_TARGET=${IOS_DEPLOYMENT_TARGET}"
  fi

  cmake -S "$ROOT_DIR" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_OSX_SYSROOT="$sdk_path" \
    -DCMAKE_OSX_ARCHITECTURES="$archs" \
    $deployment_target >&2

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
#
# We bundle three header surfaces:
#   1. `capnp_c.h` + `module.modulemap` — the minimal C API exposed as the
#      `CapnpCLib` Swift module (the Swift wrapper layer in `src/Capnp` calls
#      these C functions).
#   2. The upstream Cap'n Proto C++ public headers under `capnp/` and `kj/`.
#      These are consumed by downstream C++ shims that integrate generated
#      `.capnp.c++` code (e.g. Kayle ID's `verify_capnp_c.cpp`). They are NOT
#      part of the Swift module — they are public headers reached via
#      `#include "capnp/message.h"` from C++/Objective-C++ sources.
#
# Bundling the upstream headers means consumers no longer need bespoke
# HEADER_SEARCH_PATHS pointing into a checkout of this package's source tree.
HEADERS_DIR="$BUILD_ROOT/headers"
rm -rf "$HEADERS_DIR"
mkdir -p "$HEADERS_DIR/capnp" "$HEADERS_DIR/kj"
cp "$ROOT_DIR/src/CapnpCLib/include/capnp_c.h" "$HEADERS_DIR/"
cp "$ROOT_DIR/src/CapnpCLib/module.modulemap" "$HEADERS_DIR/"
find "$ROOT_DIR/capnproto/c++/src/capnp" -maxdepth 1 -name "*.h" -exec cp {} "$HEADERS_DIR/capnp/" \;
find "$ROOT_DIR/capnproto/c++/src/kj" -maxdepth 1 -name "*.h" -exec cp {} "$HEADERS_DIR/kj/" \;
# Cap'n Proto and KJ have a few sub-namespaced header dirs (compat/, parse/,
# ...). Mirror their layout under Headers/ so existing `#include` paths keep
# working unchanged.
for sub_dir in "$ROOT_DIR/capnproto/c++/src/capnp"/*/ "$ROOT_DIR/capnproto/c++/src/kj"/*/; do
  if [[ -d "$sub_dir" ]]; then
    rel="${sub_dir#"$ROOT_DIR/capnproto/c++/src/"}"
    rel="${rel%/}"
    mkdir -p "$HEADERS_DIR/$rel"
    find "$sub_dir" -maxdepth 1 -name "*.h" -exec cp {} "$HEADERS_DIR/$rel/" \;
  fi
done

rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
  -library "$LIB_MACOS" -headers "$HEADERS_DIR" \
  -library "$LIB_IOS" -headers "$HEADERS_DIR" \
  -library "$LIB_IOSSIM" -headers "$HEADERS_DIR" \
  -output "$XCFRAMEWORK_PATH"

echo "Built $XCFRAMEWORK_PATH"
