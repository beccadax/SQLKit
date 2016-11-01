import PackageDescription

let package = Package(
	name: "SQL",
	dependencies: [
        .Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", majorVersion: 2, minor: 0),
    ]
)
