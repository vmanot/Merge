// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Merge",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "Merge", targets: ["Merge"])
    ],
    targets: [
        .target(name: "Merge", dependencies: [], path: "Sources"),
        .testTarget(name: "MergeTests", dependencies: ["Merge"], path: "Tests")
    ]
)
