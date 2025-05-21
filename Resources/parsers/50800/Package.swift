// swift-tools-version:5.8
import PackageDescription

let package = Package(
  name: "parser",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", from: "601.0.1"),
  ],
  targets: [
    .executableTarget(
      name: "parser",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ],
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
      ]
    ),
    .testTarget(
      name: "Tests",
      dependencies: [
        .target(name: "parser"),
      ],
      resources: [.process("Fixtures")]
    )
  ]
)
