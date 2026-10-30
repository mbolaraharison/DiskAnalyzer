// swift-tools-version:5.9
import PackageDescription

// Dependency rule: Domain <- Infrastructure, Domain <- Presentation; the app target wires them together.
let package = Package(
    name: "DiskAnalyzer",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "DiskDomain"),
        .target(name: "DiskInfrastructure", dependencies: ["DiskDomain"]),
        .target(name: "DiskPresentation", dependencies: ["DiskDomain"]),
        .executableTarget(name: "DiskAnalyzer", dependencies: ["DiskDomain", "DiskInfrastructure", "DiskPresentation"]),
    ]
)
