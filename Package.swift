// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "swift-ast-explorer",
    dependencies: [
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50300.0")),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.1.10"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "swift-ast-explorer",
            dependencies: [
                "SwiftSyntax",
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "swift-ast-explorerTests",
            dependencies: ["swift-ast-explorer"]
        ),
    ]
)
