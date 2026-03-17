// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownViewer",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "MarkdownViewerLib",
            resources: [
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "MarkdownViewer",
            dependencies: ["MarkdownViewerLib"]
        ),
        .testTarget(
            name: "MarkdownViewerTests",
            dependencies: ["MarkdownViewerLib"]
        )
    ]
)
