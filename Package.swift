// swift-tools-version:5.0

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
        .library(
            name: "ParserDescriptionCompiler",
            targets: ["ParserDescriptionCompiler"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/ParserCombinators.git", from: "0.3.0"),
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "ParserDescription",
            dependencies: []
        ),
        .target(
            name: "ParserDescriptionOperators",
            dependencies: ["ParserDescription"]
        ),
        .target(
            name: "ParserDescriptionCompiler",
            dependencies: ["ParserDescription", "ParserCombinators"]
        ),
        .testTarget(
            name: "ParserDescriptionTests",
            dependencies: [
                "ParserDescription",
                "ParserDescriptionCompiler",
                "ParserDescriptionOperators",
                "DiffedAssertEqual"
            ]
        ),
    ]
)
