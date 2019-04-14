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
    ],
    dependencies: [
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
        .testTarget(
            name: "ParserDescriptionTests",
            dependencies: [
                "ParserDescription",
                "ParserDescriptionOperators",
                "DiffedAssertEqual"
            ]
        ),
    ]
)
