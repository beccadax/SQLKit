//
//  File.swift
//  
//
//  Created by Danielle Kefford on 10/20/23.
//

import PostgreSQLKit
import Foundation

let dbUrl = URL(string: "postgres://localhost/danielle")!
let db = SQLDatabase<PostgreSQL>(url: dbUrl)
let connection = try db.makeConnection()
let parts = try connection.query("SELECT * FROM parts")
let partKey = try parts.columnKey(forName: "id", as: String.self)

for part in parts.rows {
    let id = try part.value(for: partKey)
    print("\(id)")
}

//for part in parts.rowIterator {
//  let id = try part.value(for: partKey)
//  print("\(id)")
//}
