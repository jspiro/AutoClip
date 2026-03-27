// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipWatch",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/Settings.git",
            from: "3.1.0"),
        // Step 5: Sparkle for auto-updates
    ],
    targets: [
        .executableTarget(
            name: "ClipWatch",
            dependencies: ["Settings"],
            path: "Sources/ClipWatch"
        ),
    ]
)
