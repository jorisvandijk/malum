// swift-tools-version: 6.2

import PackageDescription

/// Every target treats warnings as errors.
let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

var targets: [Target] = [
    .target(
        name: "MalumCore",
        dependencies: [.product(name: "TOMLKit", package: "TOMLKit")],
        swiftSettings: strict
    ),
    .testTarget(name: "MalumCoreTests", dependencies: ["MalumCore"], swiftSettings: strict),
]

// The Linux build and tests never see the macOS-only targets.
#if os(macOS)
    targets += [
        .target(name: "MalumPlatform", dependencies: ["MalumCore"], swiftSettings: strict),
        .executableTarget(
            name: "Malum", dependencies: ["MalumCore", "MalumPlatform"], swiftSettings: strict),
    ]
#endif

let package = Package(
    name: "Malum",
    platforms: [.macOS(.v26)],
    dependencies: [
        // Reports TOML syntax errors with their line and column as numbers, not inside a message.
        .package(url: "https://github.com/LebJe/TOMLKit", exact: "0.6.0")
    ],
    targets: targets
)
