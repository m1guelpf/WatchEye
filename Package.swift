// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WatchEye",
    platforms: [
        .macOS(.v14),
        .macCatalyst(.v17),
    ],
    products: [
        .library(name: "WatchEye", type: .dynamic, targets: ["WatchEye"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skyfallsin/AXSwift", branch: "main"),
    ],
    targets: [
        .target(name: "WatchEye", dependencies: ["AXSwift"], path: "./src"),
    ]
)
