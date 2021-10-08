// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "rxswift-composable-architecture",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "ComposableArchitecture",
      targets: ["ComposableArchitecture"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.2.0"),
    .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.7.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.1"),
  ],
  targets: [
    .target(
      name: "ComposableArchitecture",
      dependencies: [
        "RxSwift",
        .product(name: "RxRelay", package: "RxSwift"),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]),
    .testTarget(
      name: "ComposableArchitectureTests",
      dependencies: ["ComposableArchitecture"]),
    .executableTarget(
      name: "swift-composable-architecture-benchmark",
      dependencies: [
        "ComposableArchitecture",
        .product(name: "Benchmark", package: "Benchmark"),
      ]
    ),
  ]
)
