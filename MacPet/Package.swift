// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPet",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "MacPet", targets: ["MacPet"])
    ],
    targets: [
        .executableTarget(
            name: "MacPet",
            path: "Sources/MacPet",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
