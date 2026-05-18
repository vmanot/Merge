// swift-tools-version:6.1

import CompilerPluginSupport
import PackageDescription

var package = Package(
    name: "Merge",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Merge",
            targets: [
                "CommandLineToolSupport",
                "ShellScripting",
                "SwiftDI",
                "Merge",
            ],
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
        .package(url: "https://github.com/preternatural-fork/swift-subprocess.git", from: "0.4.1")
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
                "SwiftDI",
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
                "Merge",
                .product(
                    name: "Subprocess",
                    package: "swift-subprocess",
                    condition: .when(platforms: [.macOS])
                ),
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
                "CommandLineToolSupportMacros",
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
        .macro(
            name: "CommandLineToolSupportMacros",
            dependencies: [
                .product(name: "MacroBuilder", package: "Swallow"),
            ],
            path: "Macros/CommandLineToolSupportMacros",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "CommandLineSupportTests",
            dependencies: [
                "CommandLineToolSupport",
            ],
            path: "Tests/CommandLineSupport",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "MergeTests",
            dependencies: [
                "Merge",
            ],
            path: "Tests/Merge",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "ShellScriptingTests",
            dependencies: [
                "Merge",
                "ShellScripting",
            ],
            path: "Tests/ShellScripting",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "SwiftDITests",
            dependencies: [
                "Merge",
                "SwiftDI",
            ],
            path: "Tests/SwiftDI",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
