// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorktreeManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WorktreeManager", targets: ["WorktreeManager"]),
        .library(name: "DecomposeKit", targets: ["DecomposeKit"])
    ],
    targets: [
        .target(
            name: "DecomposeKit",
            path: "Sources/DecomposeKit"
        ),
        .executableTarget(
            name: "WorktreeManager",
            dependencies: ["DecomposeKit"],
            path: "Sources",
            exclude: [
                "DecomposeKit"
            ]
        ),
        .testTarget(
            name: "WorktreeManagerTests",
            dependencies: ["WorktreeManager"],
            path: "Tests"
        )
    ]
)
