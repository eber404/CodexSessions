// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "codex-usage",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "CodexUsageCore", targets: ["CodexUsageCore"]),
        .executable(name: "CodexSessions", targets: ["CodexSessions"]),
    ],
    targets: [
        .target(name: "CodexUsageCore"),
        .executableTarget(
            name: "CodexSessions",
            dependencies: ["CodexUsageCore"],
            path: "Sources/CodexUsageBar",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-interposable"], .when(configuration: .debug)),
            ]
        ),
        .testTarget(name: "CodexUsageCoreTests", dependencies: ["CodexUsageCore"]),
        .testTarget(name: "CodexSessionsTests", dependencies: ["CodexSessions"]),
    ]
)
