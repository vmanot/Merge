// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "Merge",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Merge",
            targets: [
                "AppDependencies",
                "Merge"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0-beta.1"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master")
    ],
    targets: [
        .target(
            name: "AppDependencies",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/AppDependencies",
            swiftSettings: []
        ),
        .target(
            name: "Merge",
            dependencies: [
                "AppDependencies",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "Swallow",
                "SwiftUIX"
            ],
            path: "Sources/Merge",
            swiftSettings: []
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
