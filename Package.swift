// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DNSHelper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DNSHelper",
            path: "DNSHelper",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
