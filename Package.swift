// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NovaOS",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "NovaOS", targets: ["NovaOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "NovaOS",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources",
            sources: ["NovaOSApp.swift", "NovaNavigation.swift"]
        )
    ]
)
