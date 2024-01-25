// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jira",
    platforms: [.macOS(.v12), .iOS(.v12)],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/apple/swift-tools-support-core.git",
            from: "0.2.4"
        ),

        .package(url: "https://github.com/jpsim/Yams.git", "4.0.0"..<"6.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a
        // test suite.
        // Targets can depend on other targets in this package, and on products in packages which
        // this package depends on.
        .executableTarget(
            name: "jira",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .testTarget(
            name: "jiraTests",
            dependencies: ["jira"]
        ),
    ]
)
