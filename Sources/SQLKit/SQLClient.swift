//
//  SQLClient.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

/// Represents a potential source of SQL data.
/// 
/// A type conforming to `SQLClient` is never instantiated and in fact usually 
/// ought to be an `enum` with no cases. Rather, it specifies a series of 
/// associated types and methods which together represent all of the functionality 
/// needed by the `SQLDatabase`, `SQLConnection`, `SQLQuery`, `SQLRowIterator`, 
/// and `SQLRow` types.
/// 
/// The associated types specified in `SQLClient` are opaque instances which back 
/// each of these types. Client authors can use these if they wish to expose 
/// types of the underlying database client library for low-level access, or they 
/// can instead provide totally opaque types with no user-visible API surface.
/// 
/// Users only use `SQLClient`-conforming types as generic parameters to 
/// other types: `SQLDatabase<SomeClient>`, `SQLQuery<SomeClient>`, etc. The 
/// best name for a `SQLClient`-conforming type thus usually does *not* include 
/// `Client`, but merely names the engine: `PostgreSQL`, `SQLite`, etc.
public protocol SQLClient: _SQLClient {
    /// The state backing a `SQLDatabase<Self>` instance.
    associatedtype DatabaseState
    
    /// The state backing a `SQLConnection<Self>` instance.
    associatedtype ConnectionState
    
    /// The state backing a `SQLQuery<Self>` instance.
    associatedtype QueryState
    
    /// The state backing a `SQLRowIterator<Self>` or `SQLRowCollection<Self>` 
    /// instance.
    /// 
    /// This type should be `Sequence` of `RowState`s. When a user accesses the 
    /// `rowIterator` or `rows` property of a `SQLQuery`, the `SQLRowIterator` or 
    /// `SQLRowCollection` instance returned will use this type to access the rows, 
    /// wrapping each state in a `SQLRow` instance.
    /// 
    /// In addition to conforming to `Sequence`, this type should usually either 
    /// conform to `IteratorProtocol` or `Collection` (or one of its sub-protocols). 
    /// `RowStateSequence`s which conform to `IteratorProtocol` can only be 
    /// iterated over once; ones which conform to `Collection` can be iterated over 
    /// repeatedly and their indices can be used to revisit an earlier row.
    /// 
    /// - Note: If this type conforms to `Collection`, a `SQLQuery<Self>` will have 
    ///          a `rows` property.
    // 
    // WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
    associatedtype RowStateSequence: Sequence /* where Iterator.Element == RowState */
    
    /// The state backing a `SQLRow` instance.
    associatedtype RowState
    
    /// Returns true if this `SQLClient` is the appropriate one to handle `url`.
    /// 
    /// `supports(_:)` may return `true` even if connecting to the URL will fail.
    /// The primary goal of a `supports(_:)` implementation is to be reasonably 
    /// certain that this `SQLClient`, as opposed to others which might be in use, 
    /// is the one intended for the URL in question. Depending on the database 
    /// engine, this may be handled purely by examining the URL itself, looking for 
    /// (for instance) a unique `scheme`. On the other hand, if the URL uses a 
    /// common scheme like `file` or `https` and has no other distinguishing 
    /// features, `supports(_:)` may need to actually examine the resource 
    /// represented by the URL to ensure it's supported.
    /// 
    /// - SeeAlso: `SQLDatabase.Type.supports(_:)`
    static func supports(_ url: URL) -> Bool
    
    /// Creates a `DatabaseState` for connecting to the indicated `url`.
    /// 
    /// - SeeAlso: `SQLDatabase.init(url:)`
    static func makeDatabaseState(url: URL) -> DatabaseState
    
    /// Creates a `ConnectionState` for a connection to the database represented by 
    /// `databaseState`.
    /// 
    /// - Throws: If the connection cannot be made. Errors will be wrapped in a 
    ///             `SQLError.connectionFailed` error.
    /// 
    /// - SeeAlso: `SQLDatabase.makeConnection()`
    static func makeConnectionState(with databaseState: DatabaseState) throws -> ConnectionState
    
    /// Executes `statement` using the connection represented by `connectionState`, 
    /// returning no value.
    /// 
    /// - Throws: If the statement cannot be executed. Errors will be wrapped in a 
    ///             `SQLError.executionFailed` error.
    /// 
    /// - SeeAlso: `SQLConnection.execute(_:)`
    static func execute(_ statement: SQLStatement, with connectionState: ConnectionState) throws
    
    /// Executes `statement` using the connection represented by `connectionState`, 
    /// returning a sequence of auto-created values of `idColumnName`, a column of 
    /// type `idType`, of newly-inserted rows. 
    /// 
    /// - Throws: If the statement cannot be executed. Errors will be wrapped in a 
    ///             `SQLError.executionFailed` error.
    /// 
    /// - SeeAlso: `SQLConnection.execute(_:returningIDs:as:)`
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, with connectionState: ConnectionState) throws -> AnySequence<Value>
    
    /// Queries the database with `statement` using the connection reprepresented 
    /// by `connectionState`, returning a `QueryState` which will be wrapped into a 
    /// `SQLQuery` object.
    /// 
    /// - Throws: If the statement cannot be executed. Errors will be wrapped in a 
    ///             `SQLError.executionFailed` error.
    /// 
    /// - SeeAlso: `SQLConnection.query(_:)`
    static func makeQueryState(_ statement: SQLStatement, with connectionState: ConnectionState) throws -> QueryState
    
    /// Retrieves a `SQLColumnKey` for the column named `name`, of the type 
    /// `valueType`, from the query represented by `queryState`.
    /// 
    /// - Throws: If a column with that name does not exist or, optionally, is of 
    ///             the wrong type.
    ///             Errors will be wrapped in a `SQLError.columnInvalid` error.
    /// 
    /// - Warning: This method should *not* throw if the column is nullable but the 
    ///              provided type is non-optional. The `SQLNullableColumnKey` calls 
    ///              use this method to construct their keys.
    /// 
    /// - SeeAlso: `SQLQuery.columnKey(forName:as:)`
    static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, with queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value>
    
    /// Retrieves a `SQLColumnKey` for the column at zero-based index `index`, 
    /// of type `valueType`, from the query represented by `queryState`.
    /// 
    /// - Throws: If a column at that index does not exist or, optionally, is of the 
    ///             wrong type.
    ///             Errors will be wrapped in a `SQLError.columnInvalid` error.
    /// 
    /// - Note: `SQLClient`s may choose to check types either when creating a 
    ///          column key or when accessing a value using a column key. In either 
    ///          case, they should throw `SQLError.columnNotConvertible` if the type 
    ///          is not valid.
    /// 
    /// - Warning: This method should *not* throw if the column is nullable but the 
    ///              provided type is non-optional. The `SQLNullableColumnKey` calls 
    ///              use this method to construct their keys.
    /// 
    /// - SeeAlso: `SQLQuery.columnKey(at:as:)`
    static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, with queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value>
    
    /// Returns the number of rows in the result set for the query represented by 
    /// `queryState`.
    /// 
    /// - Note: This should *not* destructively iterate over the rows.
    /// 
    /// - SeeAlso: `SQLQuery.count`
    static func count(with queryState: QueryState) -> Int
    
    /// Creates a `RowStateSequence` for the rows returned by the given 
    /// `queryState`.
    /// 
    /// - Precondition: Unless `RowStateSequence` conforms to `Collection`, this 
    ///                   method may only be called once for a given `queryState`.
    /// 
    /// - SeeAlso: `SQLQuery.rowIterator`, `SQLQuery.rows`, `SQLQuery.onlyRow()`
    static func makeRowStateSequence(with queryState: QueryState) -> RowStateSequence
    
    /// Returns the value of the column with the given `key` for the given `rowState`, 
    /// as retrieved by the given `statement`.
    /// 
    /// - Parameter key: A column key from the query that produced this row.
    /// - Parameter rowState: The `RowState` representing the row to be used.
    /// - Parameter statement: The statement originally queried to produce 
    ///               `rowState`. Used in error reporting.
    /// 
    /// - Throws: If the value for `key` is `NULL` or of the wrong type.
    ///             Errors will be wrapped in a `SQLError.valueInvalid` error.
    /// 
    /// - Precondition: `key` must have come from the same query state as 
    ///                  `rowState`.
    /// 
    /// - Note: `SQLClient`s may choose to check types either when creating a 
    ///          column key or when accessing a value using a column key. In either 
    ///          case, they should throw `SQLError.columnNotConvertible` if the type 
    ///          is not valid.
    /// 
    /// - Note: This method is called for both non-nullable and nullable column 
    ///          keys. For nullable keys, the thrown error is caught and returned as 
    ///          `nil`.
    /// 
    /// - SeeAlso: `SQLRow.value(for:)`
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, with rowState: RowState) throws -> Value?
}
