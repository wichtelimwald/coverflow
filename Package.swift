// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CoverFlow",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "CoverFlow",
            targets: ["CoverFlow"]
        ),
    ],
    dependencies: [
        // Zero external dependencies — see docs/decisions/ADR-0010-spinoff-from-monorepo.md
    ],
    targets: [
        .target(
            name: "CoverFlow",
            dependencies: [],
            path: "Sources/CoverFlow",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "CoverFlowTests",
            dependencies: ["CoverFlow"],
            path: "Tests/CoverFlowTests"
        ),
    ]
)
