// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TurboBoostSwitcher",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "TurboBoostSwitcherHelper", targets: ["HelperTool"]),
        .library(name: "SharedXPC", targets: ["SharedXPC"])
    ],
    dependencies: [
        .package(url: "https://github.com/trilemma-dev/SecureXPC.git", from: "0.8.0"),
        .package(url: "https://github.com/trilemma-dev/Blessed.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "HelperTool",
            dependencies: [
                "SharedXPC",
                .product(name: "SecureXPC", package: "SecureXPC")
            ],
            path: "HelperTool"
        ),
        .target(
            name: "SharedXPC",
            dependencies: [
                .product(name: "SecureXPC", package: "SecureXPC")
            ],
            path: "Shared/XPC"
        )
    ]
)