// swift-tools-version:5.8
import PackageDescription

let package = Package(
  name: "swift-ast-explorer",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.96.0"),
    .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
    .package(url: "https://github.com/apple/swift-tools-support-core", from: "0.6.1"),
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Leaf", package: "leaf"),
        .product(name: "TSCBasic", package: "swift-tools-support-core"),
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
      ]
    )
  ]
)
