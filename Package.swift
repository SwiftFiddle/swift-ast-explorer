// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ast-explorer",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/SwiftSyntax.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "swift-ast-explorer", dependencies: ["Utility", "SwiftSyntax"]),
    ]
)
