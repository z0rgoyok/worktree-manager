// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorktreeManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WorktreeManager", targets: ["WorktreeManager"])
    ],
    targets: [
        .executableTarget(
            name: "WorktreeManager",
            path: "Sources"
        ),
        .testTarget(
            name: "WorktreeManagerTests",
            dependencies: ["WorktreeManager"],
            path: "Tests"
        )
    ]
)
