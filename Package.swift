// swift-tools-version:5.10

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
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
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

func addUnsafeFlags(to targets: inout [Target]) {
    let unsafeFlags: [SwiftSetting] = [
        .enableExperimentalFeature("AccessLevelOnImport"),
        .unsafeFlags([
            "-Xfrontend",
            "-disable-autolink-framework",
            "-Xfrontend",
            "-enforce-exclusivity=unchecked",
            "-Xfrontend",
            "-validate-tbd-against-ir=none"
        ])
    ]
    
    for i in 0..<targets.count {
        targets[i].swiftSettings = unsafeFlags
    }
}

addUnsafeFlags(to: &package.targets)
