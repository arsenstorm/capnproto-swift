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
        .binaryTarget(
            name: "CapnpCLib",
            path: "Artifacts/Capnp.xcframework"
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
