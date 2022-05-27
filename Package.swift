// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NoobECS",
    products: [
        .library(name: "NoobECS",targets: ["NoobECS"]),
        .library(name: "NoobECSStores", targets: ["NoobECSStores"])
    ],
    targets: [
        .target(name: "NoobECS", dependencies: []),
        .target(name: "NoobECSStores", dependencies: ["NoobECS"]),
        .testTarget(
            name: "NoobECSTests",
            dependencies: ["NoobECSStores", "NoobECS"]),
    ]
)
