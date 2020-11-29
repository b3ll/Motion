// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MotionBenchmark",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MotionBenchmark",
            targets: ["MotionBenchmark"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "Motion", path: "../"),
        .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MotionBenchmark",
            dependencies: [
                "Motion",
                "Benchmark",
            ]),
        .target(
            name: "MotionBenchmarkRunner",
            dependencies: [
                "MotionBenchmark",
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
