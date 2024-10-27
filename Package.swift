// swift-tools-version:5.10

import PackageDescription

var package = Package(
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
                "CommandLineToolSupport",
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
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .target(
            name: "CommandLineToolSupport",
            dependencies: [
                "Swallow",
            ],
            path: "Sources/CommandLineToolSupport",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .target(
            name: "Merge",
            dependencies: [
                "CommandLineToolSupport",
                "Swallow",
                .product(name: "SwallowMacrosClient", package: "Swallow"),
                "SwiftDI"
            ],
            path: "Sources/Merge",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .target(
            name: "Shell",
            dependencies: [
                "Merge"
            ],
            path: "Sources/Shell",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "MergeTests",
            dependencies: [
                "Merge",
                "Shell",
            ],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
