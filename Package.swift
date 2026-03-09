// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AidokuCrossPlatform",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "AidokuCore", targets: ["AidokuCore"]),
        .library(name: "AidokuAppleAdapters", targets: ["AidokuAppleAdapters"]),
        .library(name: "AidokuAndroidAdapters", targets: ["AidokuAndroidAdapters"]),
        .library(name: "AidokuBootstrap", targets: ["AidokuBootstrap"])
    ],
    targets: [
        .target(
            name: "AidokuCore"
        ),
        .target(
            name: "AidokuAppleAdapters",
            dependencies: ["AidokuCore"]
        ),
        .target(
            name: "AidokuAndroidAdapters",
            dependencies: ["AidokuCore"]
        ),
        .target(
            name: "AidokuBootstrap",
            dependencies: [
                "AidokuCore",
                "AidokuAppleAdapters",
                "AidokuAndroidAdapters"
            ]
        ),
        .testTarget(
            name: "AidokuCoreTests",
            dependencies: [
                "AidokuCore",
                "AidokuAppleAdapters",
                "AidokuAndroidAdapters",
                "AidokuBootstrap"
            ]
        )
    ]
)
