// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "SQLKit",
    products: [
        .library(
            name: "SQLKit",
            targets: ["SQLKit"]),
        .executable(
            name: "SQLKitTest",
            targets: ["SQLKitTest"]),
    ],
    targets: [
        .executableTarget(
            name: "SQLKitTest",
            dependencies: ["PostgreSQLKit"]),
        .target(
            name: "SQLKit",
            dependencies: []),
        .target(
            name: "PostgreSQLKit",
            dependencies: ["SQLKit", "CorePostgreSQL"]),
        .target(
            name: "CorePostgreSQL",
            dependencies: ["Clibpq"]),
        .systemLibrary(
            name: "Clibpq",
            pkgConfig: "libpq",
            providers: [
                .brew(["libpq"]),
                .apt(["libpq-dev"])
            ]
        ),
    ]
)
