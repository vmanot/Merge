// swift-tools-version:5.9

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
                "Shell",
                "SwiftDI",
                "Merge"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "SwiftDI",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/SwiftDI",
            swiftSettings: []
        ),
        .target(
            name: "Merge",
            dependencies: [
                "Swallow",
                .product(name: "SwallowMacrosClient", package: "Swallow"),
                "SwiftDI"
            ],
            path: "Sources/Merge",
            swiftSettings: []
        ),
        .target(
            name: "Shell",
            dependencies: [
                "Merge"
            ],
            path: "Sources/Shell",
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
