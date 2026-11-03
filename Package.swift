// swift-tools-version: 6.2

import PackageDescription

/// Every target treats warnings as errors.
let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

var targets: [Target] = [
    .target(name: "MalumCore", swiftSettings: strict),
    .testTarget(name: "MalumCoreTests", dependencies: ["MalumCore"], swiftSettings: strict),
]

// The Linux build and tests never see the macOS-only targets.
#if os(macOS)
    targets += [
        .target(name: "MalumPlatform", dependencies: ["MalumCore"], swiftSettings: strict),
        .executableTarget(name: "Malum", dependencies: ["MalumCore", "MalumPlatform"], swiftSettings: strict),
    ]
#endif

let package = Package(
    name: "Malum",
    platforms: [.macOS(.v26)],
    targets: targets
)
