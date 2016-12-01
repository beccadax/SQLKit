import PackageDescription

let package = Package(
	name: "SQLKit",
  targets: [
    Target(name: "SQLKit"),
    Target(name: "PostgreSQLKit", dependencies: ["SQLKit", "CorePostgreSQL"]),
    Target(name: "CorePostgreSQL")
  ],
	dependencies: [
    .Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", majorVersion: 2, minor: 0),
  ]
)
