// swift-tools-version:5.8
import PackageDescription

let package = Package(
  name: "swift-ast-explorer",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", from: "508.0.0"),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.77.0"),
    .package(url: "https://github.com/vapor/leaf.git", from: "4.2.4"),
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Leaf", package: "leaf"),
      ],
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
      ]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: [
        .target(name: "App"),
        .product(name: "XCTVapor", package: "vapor"),
      ],
      resources: [.process("Fixtures")]
    )
  ]
)
