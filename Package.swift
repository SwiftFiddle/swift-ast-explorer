// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "swift-ast-explorer",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50500.0")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.51.1"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.1.3"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "SwiftSyntax",
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
