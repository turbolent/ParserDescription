// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "ParserDescription",
    products: [
        .library(
            name: "ParserDescription",
            targets: ["ParserDescription"]
        ),
        .library(
            name: "ParserDescriptionOperators",
            targets: ["ParserDescriptionOperators"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/ParserCombinators.git", .branch("master")),
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "ParserDescription",
            dependencies: []),
         .target(
            name: "ParserDescriptionOperators",
            dependencies: ["ParserDescription"]),
        .target(
            name: "ParserDescriptionCompiler",
            dependencies: ["ParserDescription", "ParserCombinators"]),
        .testTarget(
            name: "ParserDescriptionTests",
            dependencies: ["ParserDescription", "ParserDescriptionCompiler", "ParserDescriptionOperators", "DiffedAssertEqual"]),
    ]
)
