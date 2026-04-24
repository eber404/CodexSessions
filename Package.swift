// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "codex-watch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "CodexWatchCore", targets: ["CodexWatchCore"]),
        .executable(name: "CodexWatch", targets: ["CodexWatch"]),
    ],
    targets: [
        .target(name: "CodexWatchCore"),
        .executableTarget(
            name: "CodexWatch",
            dependencies: ["CodexWatchCore"],
            path: "Sources/CodexWatch",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-interposable"], .when(configuration: .debug)),
            ]
        ),
        .testTarget(name: "CodexWatchCoreTests", dependencies: ["CodexWatchCore", "CodexWatch"]),
        .testTarget(name: "CodexWatchTests", dependencies: ["CodexWatch"]),
    ]
)
