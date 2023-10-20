// swift-tools-version: 5.6

import PackageDescription

let package = Package(
	name: "SQLKit",
    products: [
        .library(
            name: "SQLKit",
            type: .dynamic,
            targets: ["SQLKit"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git",
            from: "4.0.0"),
    ],
    targets: [
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
