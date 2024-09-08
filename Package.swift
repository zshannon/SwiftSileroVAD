// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSileroVAD",
    platforms: [.iOS(.v12), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftSileroVAD",
            targets: ["SwiftSileroVAD"]
        ),
        .executable(name: "SwiftSileroVADExample", targets: ["SwiftSileroVADExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit", .upToNextMajor(from: "5.6.2")),
        .package(url: "https://github.com/AudioKit/AudioKitEX", .upToNextMajor(from: "5.4.0")),
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
                ],
                resources: [.process("Resources")]),
        .testTarget(
            name: "SwiftSileroVADTests",
            dependencies: ["SwiftSileroVAD"],
            resources: [.process("Resources")]
        ),
        .executableTarget(name: "SwiftSileroVADExample",
                          dependencies: ["AudioKit", "AudioKitEX", "SwiftSileroVAD"],
                          path: "SwiftSileroVADExample/SwiftSileroVADExample",
                          linkerSettings: [.unsafeFlags(["-sectcreate",
                                                         "__TEXT",
                                                         "__info_plist",
                                                         "SwiftSileroVADExample/SwiftSileroVADExample/Info.plist"])]),
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
//    .enableExperimentalFeature("IsolatedAny"), // enable in Swift 6
]

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: swiftSettings)
    target.swiftSettings = settings
}
