// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target {
    var asDependency: Target.Dependency {
        Target.Dependency(stringLiteral: self.name)
    }
}

let dependencies: [Package.Dependency] = []

enum CorePackage {}

let LayerDefenceKit = Target.target(
    name: "LayerDefenceKit",
    dependencies: [],
    path: "Sources/LayerDefenceKit",
    resources: [
        .process("Resources")
    ]
)

let package = Package(
    name: "LayerDefenceKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LayerDefenceKit",
            targets: [
                LayerDefenceKit.name
            ]
        ),
    ],
    dependencies: dependencies,
    targets: [
        LayerDefenceKit
    ]
)
