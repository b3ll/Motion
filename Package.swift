// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Motion",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_14),
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
        .package(url: "https://github.com/apple/swift-numerics", from: "0.0.8"),
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
    swiftLanguageVersions: [.v5]
)
