// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreedomEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FreedomEngine", targets: ["FreedomEngine"])
    ],
    targets: [
        .target(name: "FreedomEngine"),
        .testTarget(
            name: "FreedomEngineTests",
            dependencies: ["FreedomEngine"],
            resources: [.copy("Fixtures")]
        )
    ]
)
