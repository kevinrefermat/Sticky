// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sticky",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "Sticky",
            targets: ["Sticky"]
        )
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "Sticky",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "StickyTests",
            dependencies: ["Sticky"],
            path: "Tests"
        )
    ]
)
