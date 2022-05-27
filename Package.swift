// swift-tools-version: 5.6
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
            dependencies: ["NoobECSStores", "NoobECS"]
        ),
    ]
)
