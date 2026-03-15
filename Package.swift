// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Umami",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Umami", targets: ["Umami"]),
        .library(name: "UmamiCore", targets: ["UmamiCore"]),
        .library(name: "UmamiAPI", targets: ["UmamiAPI"]),
        .library(name: "UmamiTracker", targets: ["UmamiTracker"]),
    ],
    targets: [
        .target(name: "UmamiCore"),
        .target(name: "UmamiAPI", dependencies: ["UmamiCore"]),
        .target(name: "UmamiTracker", dependencies: ["UmamiCore"]),
        .target(name: "Umami", dependencies: ["UmamiCore", "UmamiAPI", "UmamiTracker"]),
        .testTarget(name: "UmamiTests", dependencies: ["Umami"]),
    ]
)
