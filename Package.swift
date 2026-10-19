// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "DivGrid",
    platforms: [.macOS("26.0")],
    targets: [
        // Pure logic (grid math, coordinates, shortcuts, preferences). No AppKit, so it is unit-testable.
        .target(name: "DivGridCore"),
        .executableTarget(
            name: "DivGrid",
            dependencies: ["DivGridCore"]
        ),
        .testTarget(name: "DivGridCoreTests", dependencies: ["DivGridCore"]),
    ]
)
