// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TradApp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TradApp",
            path: "Sources/TradApp",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
