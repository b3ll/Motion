// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Motion",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Motion",
            targets: ["Motion"]),
        .library(
            name: "Graphing",
            targets: ["Graphing"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Motion",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics"),
            ]),
        .testTarget(
            name: "MotionTests",
            dependencies: ["Motion"]),
        .target(
            name: "Graphing",
            dependencies: [
                "Motion",
            ]),
    ],
    swiftLanguageModes: [.v5, .v6]
)
