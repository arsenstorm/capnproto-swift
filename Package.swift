// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapnpSwift",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
    ],
    products: [
        .library(name: "Capnp", targets: ["Capnp"]),
    ],
    targets: [
        // The binary target is shipped via GitHub Releases rather than
        // committed into the repo — keeps the source tree lean and matches
        // the SPM convention for prebuilt frameworks.
        //
        // To rebuild + ship a new version:
        //   1. Run `scripts/build-xcframework.sh`
        //   2. `cd Artifacts && zip -r Capnp.xcframework.zip Capnp.xcframework`
        //   3. `swift package compute-checksum Capnp.xcframework.zip`
        //   4. Bump the URL + checksum below
        //   5. Tag the release, push the tag, attach the zip to the release.
        .binaryTarget(
            name: "CapnpCLib",
            url: "https://github.com/arsenstorm/capnproto-swift/releases/download/1.0.0/Capnp.xcframework.zip",
            checksum: "045a1b1875e8f2eea2f41577939b0bb2e6f70944330a6be4fdc50f74a772b72b"
        ),
        .target(
            name: "Capnp",
            dependencies: ["CapnpCLib"],
            path: "src/Capnp"
        ),
        .testTarget(
            name: "CapnpTests",
            dependencies: ["Capnp"],
            path: "tests/CapnpTests"
        ),
    ]
)
