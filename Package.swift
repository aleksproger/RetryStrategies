// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "retry-strategies",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "RetryStrategies", targets: ["RetryStrategies"]),
        .library(name: "RetryStrategiesTestKit", targets: ["RetryStrategiesTestKit"]),
    ],
    targets: [
        .target(name: "RetryStrategies"),
        .target(name: "RetryStrategiesTestKit", dependencies: ["RetryStrategies"]),
        .testTarget(name: "RetryStrategiesTests", dependencies: ["RetryStrategies", "RetryStrategiesTestKit"]),
    ]
)
