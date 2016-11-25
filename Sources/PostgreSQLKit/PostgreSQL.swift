//
//  PostgresDatabase.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation
@_exported import SQLKit
import PostgreSQL

/// A client for Postgres databases. Like all `SQLClient`s, you do not use this 
/// type directly, but rather you create a `SQLDatabase<PostgreSQL>` and derive 
/// other instances from it.
/// 
/// `PostgreSQL` supports connecting to a database using the `postgres` or 
/// `postgresql` schemes and [the format accepted by `libpq`'s 
/// `PQconnectdb(_:)`](https://www.postgresql.org/docs/9.4/static/libpq-connect.html#AEN41287).
/// 
/// `PostgreSQL.ConnectionState` and `PostgreSQL.QueryState` expose types from 
/// the library this client wraps, so you can use them to perform operations not 
/// directly supported by `SQLKit`.
public enum PostgreSQL: SQLClient {
    /// The type of `SQLDatabase<PostgreSQL>.state`.
    public struct DatabaseState {
        let url: URL
    }
    
    /// The type of `SQLConnection<PostgreSQL>.state`. This is a `PGConnection` 
    /// instance, which you can use directly if you need low-level access to the 
    /// database.
    public typealias ConnectionState = PGConnection
    
    /// The type of `SQLQuery<PostgreSQL>.state`. This is a `PGResult` instance, 
    /// which you can use directly if you need low-level access to the query results.
    public typealias QueryState = PGResult
    
    /// The type backing a `SQLRowIterator<PostgreSQL>` or 
    /// `SQLRowCollection<PostgreSQL>`. Because this type conforms to 
    /// `RandomAccessCollection`, you can access the rows returned by a query in 
    /// any order and as many times as you wish.
    public struct RowStateSequence: RandomAccessCollection {
        let queryState: QueryState
        
        public typealias Indices = DefaultRandomAccessIndices<RowStateSequence>
        
        public var startIndex: Int {
            return 0
        }
        
        public var endIndex: Int {
            return queryState.numTuples()
        }
        
        public func index(before i: Int) -> Int {
            return i - 1
        }
        
        public func index(after i: Int) -> Int {
            return i + 1
        }
        
        public func index(_ i: Int, offsetBy n: Int) -> Int {
            return i + n
        }
        
        public subscript(i: Int) -> RowState {
            return RowState(result: queryState, rowIndex: i)
        }
    }
    
    /// The type of `SQLRow<PostgreSQL>.state`.
    public struct RowState {
        let result: PGResult
        let rowIndex: Int
    }
    
    public static func supports(_ url: URL) -> Bool {
        guard let scheme = url.scheme else {
            return false
        }
        return ["postgres", "postgresql"].contains(scheme)
    }
    
    public static func makeDatabaseState(url: URL) -> DatabaseState {
        return DatabaseState(url: url)
    }
    
    public static func makeConnectionState(for databaseState: DatabaseState) throws -> ConnectionState {
        let conn = PGConnection()
        guard case .ok = conn.connectdb(databaseState.url.absoluteString) else {
            throw SQLError.connectionFailed(message: conn.errorMessage())
        }
        
        try execute("SET DateStyle = 'ISO'", for: conn)
        try execute("SET TimeZone = 'UTC'", for: conn)
        try execute("SET client_encoding = 'Unicode'", for: conn)
        
        return conn
    }
    
    public static func execute(_ statement: SQLStatement, for connectionState: ConnectionState) throws {
        _ = try makeQueryState(statement, for: connectionState)
    }
    
    public static func execute<Value : SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: PGConnection) throws -> AnySequence<Value> {
        let statementWithReturning = statement + SQLStatement(" RETURNING \(SQLStatement(raw: idColumnName))")
        let result = try makeQueryState(statementWithReturning, for: connectionState)
        
        let idKey = try columnKey(forName: idColumnName, as: idType, for: result, statement: statementWithReturning)
        return AnySequence(try RowStateSequence(queryState: result).map { try value(for: idKey, for: $0, statement: statementWithReturning) }) 
    }
    
    public static func makeQueryState(_ statement: SQLStatement, for connectionState: ConnectionState) throws -> QueryState {
        var parameters: [String?] = []
        let sql = statement.rawSQLByReplacingParameters { value in
            parameters.append(value?.sqlLiteral)
            return "$\(parameters.count)"
        }
        
        let result = connectionState.exec(statement: sql, params: parameters)
        try result.assertSucceeded(statement)
        return result
    }
    
    public static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        guard let index = queryState.columnIndex(for: name) else {
            throw SQLError.columnMissing(.name(name), statement: statement)
        }
        return SQLColumnKey(index: index, name: name)
    }
    
    public static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        guard let name = queryState.fieldName(index: index) else {
            throw SQLError.columnMissing(.index(index), statement: statement)
        }
        return SQLColumnKey(index: index, name: name)
    }
    
    public static func count(for queryState: QueryState) -> Int {
        return queryState.numTuples()
    }
    
    public static func makeRowStateSequence(for queryState: QueryState) -> RowStateSequence {
        return RowStateSequence(queryState: queryState)
    }
    
    public static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: RowState, statement: SQLStatement) throws -> Value {
        if rowState.result.fieldIsNull(tupleIndex: rowState.rowIndex, fieldIndex: key.index) {
            throw SQLError.columnNull(key, statement: statement)
        }
        
        guard let string = rowState.result.getFieldString(tupleIndex: rowState.rowIndex, fieldIndex: key.index) else {
            throw SQLError.columnMissing(.name(key.name), statement: statement)
        }
        
        guard let value = Value(sqlLiteral: string) else {
            throw SQLError.columnNotConvertible(key, sqlLiteral: string, statement: statement)
        }
        
        return value
    }
}

extension PGResult {
    func columnIndex(for name: String) -> Int? {
        for i in 0..<numFields() {
            guard fieldName(index: i) == name else {
                continue
            }
            
            return i
        }
        
        return nil
    }
    
    fileprivate func assertSucceeded(_ statement: SQLStatement, withoutNonFatalError: Bool = false) throws {
        let status = self.status()
        switch status {
        case    .commandOK,
                .tuplesOK,
                .singleTuple, 
                .nonFatalError where withoutNonFatalError:
            break
        default:
            throw SQLError.executionFailed(message: errorMessage(), statement: statement)
        }
    }
}
