//
//  PostgresDatabase.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 10/28/16.
//
//

import Foundation
import CorePostgreSQL
@_exported import SQLKit

/// A client for Postgres databases. Like all `SQLClient`s, you do not use this 
/// type directly, but rather you create a `SQLDatabase<PostgreSQL>` and derive 
/// other instances from it.
/// 
/// `PostgreSQL` supports connecting to a database using the `postgres` or 
/// `postgresql` schemes and [the format accepted by `libpq`'s 
/// `PQconnectdb(_:)`](https://www.postgresql.org/docs/9.4/static/libpq-connect.html#AEN41287).
/// 
/// `PostgreSQL` uses the `CorePostgreSQL` module to access the database, and its 
/// `ConnectionState`, `QueryState`, `RowStateSequence`, and `RowState` types 
/// all wrap `CorePostgreSQL` types. By importing `CorePostgreSQL` yourself, you 
/// can use these types to perform operations not supported by `SQLKit`.
/// 
/// `PostgreSQL` supports the following types as `SQLValue` types:
/// 
/// * `String`, `Data`, `Bool`, `Int`, `Double`, `Date`, and 
///    `SQLStringConvertible` (required by `SQLKit`)
/// * `PGDate`, `PGTime`, `PGTimestamp`, and `PGInterval` (from 
///    `CorePostgreSQL`)
/// * `Decimal`
/// 
/// - Warning: In order to function correctly, `CorePostgreSQL` must control the 
///              `client_encoding`, `DateStyle`, and `IntervalStyle` configuration 
///              parameters. Do not change these except through APIs provided by 
///              `CorePostgreSQL`.
public enum PostgreSQL: SQLClient {
    /// The type of `SQLDatabase<PostgreSQL>.state`.
    public struct DatabaseState {
        let url: URL
    }
    
    /// The type of `SQLConnection<PostgreSQL>.state`. This is a `PGConn` 
    /// instance, which you can use directly if you need low-level access to the 
    /// database.
    public typealias ConnectionState = PGConn
    
    /// The type of `SQLQuery<PostgreSQL>.state`. This is a `PGResult` instance, 
    /// which you can use directly if you need low-level access to the query results.
    public typealias QueryState = PGResult
    
    /// The type backing a `SQLRowIterator<PostgreSQL>` or 
    /// `SQLRowCollection<PostgreSQL>`. Because this type conforms to 
    /// `RandomAccessCollection`, you can access the rows returned by a query in 
    /// any order and as many times as you wish. This is a `PGResult.TupleView` 
    /// instance, which you can use directly if you need low-level access to the 
    /// rows.
    public typealias RowStateSequence = PGResult.TupleView
    
    /// The type of `SQLRow<PostgreSQL>.state`. This is a `PGResult.Tuple` 
    /// instance, which you can use directly if you need low-level access to the row.
    public typealias RowState = PGResult.Tuple
    
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
        let conn = try PGConn(connectingToURL: databaseState.url)
        
        try execute("SET TimeZone = 'UTC'", with: conn)
        
        return conn
    }
    
    public static func execute(_ statement: SQLStatement, with connectionState: ConnectionState) throws {
        _ = try makeQueryState(statement, with: connectionState)
    }
    
    public static func execute<Value : SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, with connectionState: ConnectionState) throws -> AnySequence<Value> {
        let statementWithReturning = statement + SQLStatement(" RETURNING \(SQLStatement(raw: idColumnName))")
        let result = try makeQueryState(statementWithReturning, with: connectionState)
        
        guard let index = try columnIndex(forName: idColumnName, as: idType, with: result) else {
            throw SQLColumnError.columnMissing
        }
        
        let seq = try result.tuples.map { try value(at: index, as: idType, in: $0)! }
        return AnySequence(seq)
    }
    
    public static func makeQueryState(_ statement: SQLStatement, with connectionState: ConnectionState) throws -> QueryState {
        var parameters: [PGValue?] = []
        let sql = try statement.rawSQLByReplacingParameters { value in
            parameters.append(try value.map { try $0.toPGValueForSQLKit() })
            return "$\(parameters.count)"
        }
        
        return try connectionState.execute(sql, with: parameters)
    }
    
    public static func columnIndex<Value: SQLValue>(forName name: String, as valueType: Value.Type, with queryState: QueryState) throws -> Int? {
        try valueType.checkPGValueCompatibility()
        
        guard let index = queryState.fields.index(of: name) else {
            return nil
        }
        return index
    }
    
    public static func columnName<Value: SQLValue>(at index: Int, as valueType: Value.Type, with queryState: QueryState) throws -> String? {
        try valueType.checkPGValueCompatibility()
        
        guard queryState.fields.indices.contains(index) else {
            return nil
        }
        
        let name = queryState.fields[index].name
        return name
    }
    
    public static func count(with queryState: QueryState) -> Int {
        return queryState.tuples.count
    }
    
    public static func makeRowStateSequence(with queryState: QueryState) -> RowStateSequence {
        return queryState.tuples
    }
    
    private static func value<Value: SQLValue>(at index: Int, as valueType: Value.Type, in tuple: PGResult.Tuple) throws -> Value? {
        guard let rawValue = tuple[index] else {
            return nil
        }
        
        return try Value(rawPGValueForSQLKit: rawValue)
    }
    
    public static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, with rowState: RowState) throws -> Value? {
        return try value(at: key.index, as: Value.self, in: rowState)
    }
}
