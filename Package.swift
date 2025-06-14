// swift-tools-version:6.0

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
                "ShellScripting",
                "SwiftDI",
                "Merge"
            ],
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
                .enableExperimentalFeature("AccessLevelOnImport"),
                .swiftLanguageMode(.v5),
            ]
        ),
        .target(
            name: "Merge",
            dependencies: [
                "Swallow",
                .product(name: "SwallowMacrosClient", package: "Swallow"),
                "SwiftDI"
            ],
            path: "Sources/Merge",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .swiftLanguageMode(.v5),
            ]
        ),
        .target(
            name: "ShellScripting",
            dependencies: [
                "Merge"
            ],
            path: "Sources/ShellScripting",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .swiftLanguageMode(.v5),
            ]
        ),
        .target(
            name: "CommandLineToolSupport",
            dependencies: [
                "Merge",
                "ShellScripting",
                "Swallow",
            ],
            path: "Sources/CommandLineToolSupport",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "MergeTests",
            dependencies: [
                "CommandLineToolSupport",
                "Merge",
                "ShellScripting",
            ],
            path: "Tests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
