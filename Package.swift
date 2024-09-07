// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSileroVAD",
    platforms: [.iOS(.v12), .macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftSileroVAD",
            targets: ["SwiftSileroVAD"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/microsoft/onnxruntime-swift-package-manager",
            branch: "main"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "SwiftSileroVAD",
                dependencies: [
                    .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager"),
                ]),
        .testTarget(
            name: "SwiftSileroVADTests",
            dependencies: ["SwiftSileroVAD"]
        ),
    ]
)
