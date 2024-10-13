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

/*package = Optional(package)!

extension Target.Dependency {
    var name: String {
        switch self {
            case let .targetItem(name, _):
                return name
            case let .productItem(name, package, moduleAliases, condition):
                return name
            case let .byNameItem(name, condition):
                return name
        }
    }
}

private func patchPackageToUsePrebuiltBinaries(in package: inout Package) {
    func patchMacro(_ target: Target, _ macro: String) {
        var settings = target.swiftSettings ?? []
        
        settings.append(.unsafeFlags([
            "-Xfrontend",
            "-load-plugin-executable",
            "-Xfrontend",
            "/Users/vatsal/Downloads/GitHub/vmanot/Frameworks/Swallow/XCFrameworks/SwallowMacros-tool#\(macro)"
        ]))
        
        target.swiftSettings = settings
    }
    
    if Set(package.dependencies.compactMap({ $0.name })).contains("swift-syntax") {
        package.dependencies = [
            .package(path: "XCFrameworks/packages/swift-collections"),
            .package(path: "XCFrameworks/packages/swift-syntax"),
        ]
    }
    
    for target in package.targets {
        patchMacro(target, "SwallowMacros")
    }
}

patchPackageToUsePrebuiltBinaries(in: &package)
*/
