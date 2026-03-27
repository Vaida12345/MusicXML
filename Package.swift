// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MusicXML",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MusicXML",
            targets: ["MusicXML"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Vaida12345/Essentials.git", from: "1.0.0"),
        .package(url: "https://github.com/Vaida12345/DetailedDescription.git", from: "2.1.0"),
        .package(url: "https://github.com/Vaida12345/MacroCollection.git", from: "1.0.0"),
        .package(url: "https://github.com/Vaida12345/FinderItem.git", from: "1.2.7"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.7.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MusicXML",
            dependencies: [
                "Essentials",
                "DetailedDescription",
                "ZIPFoundation",
                "MacroCollection",
                "AEXML",
                "FinderItem"
            ]
        ),
        .testTarget(
            name: "MusicXMLTests",
            dependencies: ["MusicXML", "FinderItem"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
