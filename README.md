# CapnpSwift

Swift Package that wraps Cap'n Proto's C++ library as a binary xcframework and exposes a minimal C API for Swift.

## Requirements
- Xcode (with C++23 toolchain support)
- CMake 3.16+
- Cap'n Proto submodule checked out

## Build the xcframework
This builds a multi-platform `Artifacts/Capnp.xcframework` for macOS and iOS (device + simulator):

```bash
scripts/build-xcframework.sh
```

## Use in Xcode
- Add this package to your Xcode project.
- Build the xcframework once (command above) or run it in CI.
- Import the Swift wrapper:

```swift
import Capnp

let v = Capnp.version
print("Cap'n Proto version: \(v.major).\(v.minor).\(v.micro)")
```

## Available C API
Currently exposed C functions (via `CapnpCLib`):
- `int capnp_c_version_major(void)`
- `int capnp_c_version_minor(void)`
- `int capnp_c_version_micro(void)`

## Notes
- The wrapper currently links `capnp`, `kj`, and the C shim into a single static library inside the xcframework.
- If you need more Cap'n Proto APIs, we can expand the C shim.
