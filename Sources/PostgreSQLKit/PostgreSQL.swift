//
//  PostgresDatabase.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation
@_exported import SQLKit

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
extension PostgreSQL: SQLClient {
    /// The type of `SQLDatabase<PostgreSQL>.state`.
    public struct DatabaseState {
        let url: URL
    }
    
    /// The type of `SQLConnection<PostgreSQL>.state`. This is a `PGConnection` 
    /// instance, which you can use directly if you need low-level access to the 
    /// database.
    public typealias ConnectionState = PostgreSQL.Connection
    
    /// The type of `SQLQuery<PostgreSQL>.state`. This is a `PGResult` instance, 
    /// which you can use directly if you need low-level access to the query results.
    public typealias QueryState = PostgreSQL.Result
    
    /// The type backing a `SQLRowIterator<PostgreSQL>` or 
    /// `SQLRowCollection<PostgreSQL>`. Because this type conforms to 
    /// `RandomAccessCollection`, you can access the rows returned by a query in 
    /// any order and as many times as you wish.
    public typealias RowStateSequence = PostgreSQL.Result.TupleView
    
    /// The type of `SQLRow<PostgreSQL>.state`.
    public typealias RowState = PostgreSQL.Result.Tuple
    
    public static func supports(_ url: URL) -> Bool {
        guard let scheme = url.scheme else {
            return false
        }
        return ["postgres", "postgresql"].contains(scheme)
    }
    
    public static func makeDatabaseState(url: URL) -> DatabaseState {
        return DatabaseState(url: url)
    }
    
    public static func makeConnectionState(with databaseState: DatabaseState) throws -> ConnectionState {
        let conn = try Connection(connectingToURL: databaseState.url)
        
        try execute("SET DateStyle = 'ISO'", with: conn)
        try execute("SET TimeZone = 'UTC'", with: conn)
        try execute("SET client_encoding = 'Unicode'", with: conn)
        
        return conn
    }
    
    public static func execute(_ statement: SQLStatement, with connectionState: ConnectionState) throws {
        _ = try makeQueryState(statement, with: connectionState)
    }
    
    public static func execute<Value : SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, with connectionState: ConnectionState) throws -> AnySequence<Value> {
        let statementWithReturning = statement + SQLStatement(" RETURNING \(SQLStatement(raw: idColumnName))")
        let result = try makeQueryState(statementWithReturning, with: connectionState)
        
        let idKey = try columnKey(forName: idColumnName, as: idType, with: result)
        return AnySequence(try result.tuples.flatMap { try value(for: idKey, with: $0) }) 
    }
    
    public static func makeQueryState(_ statement: SQLStatement, with connectionState: ConnectionState) throws -> QueryState {
        var parameters: [String?] = []
        let sql = statement.rawSQLByReplacingParameters { value in
            parameters.append(value?.sqlLiteral)
            return "$\(parameters.count)"
        }
        
        return try connectionState.execute(sql, with: parameters.map { Parameter(value: $0) })
    }
    
    public static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, with queryState: QueryState) throws -> SQLColumnKey<Value> {
        guard let index = queryState.fields.index(of: name) else {
            throw SQLColumnError.columnMissing
        }
        return SQLColumnKey(index: index, name: name)
    }
    
    public static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, with queryState: QueryState) throws -> SQLColumnKey<Value> {
        guard queryState.fields.indices.contains(index) else {
            throw SQLColumnError.columnMissing
        }
        
        let name = queryState.fields[index].name
        return SQLColumnKey(index: index, name: name)
    }
    
    public static func count(with queryState: QueryState) -> Int {
        return queryState.tuples.count
    }
    
    public static func makeRowStateSequence(with queryState: QueryState) -> RowStateSequence {
        return queryState.tuples
    }
    
    public static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, with rowState: RowState) throws -> Value? {
        guard let string = rowState[key.index] else {
            return nil
        }
        
        guard let value = Value(sqlLiteral: string) else {
            throw SQLValueError.valueNotConvertible(sqlLiteral: string, underlying: nil) 
        }
        
        return value
    }
}
