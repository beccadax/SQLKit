# SQLKit for Swift

`SQLKit` is a SQL client abstraction layer for Swift. It's designed to permit access to any 
SQL engine through the same uniform, convenient interface.

`SQL` 0.0.1 is a very preliminary proof-of-concept release. It includes no tests or 
documentation, and the only included SQL client, PostgreSQL, builds within the `SQL` module. 
Important work still needs to be done, particularly on handling of values. But it does work, 
and it includes some very useful features.

# Synopsis

```swift
import Foundation
import SQLKit

// Information we'll need later.
let (dbURL, userIDs): (URL, [Int]) = getParameters()

// A SQLDatabase represents connection settings to talk to a database.
// (Currently just the client and URL.)
// 
// "PostgreSQL" here is a type conforming to SQLClient. You don't use 
// SQLClients directly, but you can implement one yourself.
// 
// SQL includes an AnySQLClient type which allows your code to 
// dynamically connect to any registered database type.
let db = SQLDatabase<PostgreSQL>(url: dbURL)

// A SQLConnection<PostgreSQL> is an individual connection to the database.
let connection = try db.makeConnection()

// A SQLStatement represents a whole or partial statement. Values interpolated 
// into a SQLStatement will be passed through placeholders or escaped, unless 
// they are themselves SQLStatements.
let whereClause: SQLStatement
if userIDs.isEmpty {
  whereClause = ""
}
else {
  whereClause = "WHERE " + userIDs.map { "id = \($0)" }.joined(" OR ")
}

// Perform the actual query.
let users = try db.query("SELECT * FROM users \(whereClause)")

// A SQLQuery<PostgreSQL> represents the results of an individual query. It 
// is used for two things.
// 
// 1. Get `SQLColumnKey`s representing the columns in the result set:
let idKey = try users.columnKey(forName: "id", as: Int.self)
let nameKey = try users.columnKey(forName: "name", as: String?.self)

// 2. Access the rows through its iterator:
for user in users.rowIterator {
  let id = try user.value(for: idKey)
  let name = try user.value(for: nameKey) ?? "[no name]"
  print("\(id)\t\(name)")
}
```

# Contributions

Will be accepted by pull request, but if you're modifying the design, talk to 
me first. I'm just a little bit opinionated.

For now, the code of conduct is this: The first person who is such an asshat that 
I have to draft a real code of conduct is probably going to be banned. Don't be the 
asshat.

# Copyright

(C) 2016 Groundbreaking Software. Distributed under the MIT License.
