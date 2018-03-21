// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Caramel",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "Caramel",
            targets: ["Caramel"]),
        .library(
            name: "CaramelFramework",
            targets: ["CaramelFramework"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sharplet/Regex.git", from: "1.1.0"),
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "4.0.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.18.1"),
        .package(url: "https://github.com/yanagiba/swift-ast.git", from: "0.3.1"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Caramel",
            dependencies: ["CaramelFramework", "Rainbow"]
        ),
        .target(
            name: "CaramelFramework",
            dependencies: ["Regex", "SwiftShell", "SourceKittenFramework", "SwiftAST"]
        ),
        .testTarget(
            name: "CaramelFrameworkTests",
            dependencies: ["CaramelFramework"]),
    ]
)
