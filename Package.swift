// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "swift-ast-explorer",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", branch: "0.50600.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.56.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.1.5"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
