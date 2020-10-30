// swift-tools-version:5.3

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
        .library(
            name: "Merge",
            targets: ["Merge"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Compute.git", .branch("master")),
        .package(url: "https://github.com/vmanot/FoundationX.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Swallow.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Merge",
            dependencies: [
                "Compute",
                "FoundationX",
                "Swallow"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "MergeTests",
            dependencies: [
                "Merge"
            ],
            path: "Tests"
        )
    ]
)
