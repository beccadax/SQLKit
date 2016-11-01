//
//  SQL.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/27/16.
//
//

import Foundation

public enum SQLError: Error {
    case connectionFailed(message: String)
    case executionFailed(message: String, statement: SQLStatement)
    case noRecordsFound(statement: SQLStatement)
    case extraRecordsFound(statement: SQLStatement)
    case columnMissing(AnySQLColumnKey, statement: SQLStatement)
    case columnNull(AnySQLColumnKey, statement: SQLStatement)
    case columnNotConvertible(AnySQLColumnKey, sqlLiteral: String, statement: SQLStatement)
}
