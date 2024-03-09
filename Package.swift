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
                "SwiftDI",
                "Merge"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master")
    ],
    targets: [
        .target(
            name: "SwiftDI",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/SwiftDI",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution",
                ])
            ]
        ),
        .target(
            name: "Merge",
            dependencies: [
                "Swallow",
                "SwiftDI",
                "SwiftUIX"
            ],
            path: "Sources/Merge",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution",
                ])
            ]
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
