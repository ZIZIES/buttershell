// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Buttershell",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "buttershell", targets: ["Buttershell"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", exact: "1.10.1")
    ],
    targets: [
        .executableTarget(
            name: "Buttershell",
            dependencies: [.product(name: "SwiftTerm", package: "SwiftTerm")],
            resources: [.process("Resources")]
        )
    ]
)
