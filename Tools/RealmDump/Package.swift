// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RealmDump",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RealmDump", targets: ["RealmDump"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.50.0")
    ],
    targets: [
        .executableTarget(
            name: "RealmDump",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift")
            ],
            path: "Sources"
        )
    ]
)

