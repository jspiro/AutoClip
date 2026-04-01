// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoClip",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/Settings.git",
            from: "3.1.0"),
        .package(
            url: "https://github.com/sparkle-project/Sparkle.git",
            from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "AutoClip",
            dependencies: ["Settings", "Sparkle"],
            path: "Sources/AutoClip"
        ),
    ]
)
