// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AtavusAI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "AtavusAI",
            targets: ["AtavusAI"]
        ),
    ],
    targets: [
        .target(
            name: "AtavusAI",
            path: "Sources/AtavusAI",
            resources: []
        ),
        .testTarget(
            name: "AtavusAITests",
            dependencies: ["AtavusAI"]
        ),
    ]
)
