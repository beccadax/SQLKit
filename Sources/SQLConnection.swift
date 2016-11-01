//
//  SQLConnection.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

/// Implementation detail used to detect SQLConnections in generics. Do not use.
// WORKAROUND: #2 Swift doesn't support same-type requirements on generics
public protocol _SQLConnection {
    associatedtype Client: SQLClient
}

/// Represents a connection to a database.
/// 
/// A `SQLConnection` can be used to query or execute statements on the database. 
/// The difference between the two is that querying returns a `SQLQuery` which can 
/// be used to access the query's result, while executing returns either nothing or 
/// the IDs of rows created by the statement.
/// 
/// In either case, you will always use the `SQLStatement` type to express the 
/// statement to be executed or queried.
//
// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
// WORKAROUND: #2 Swift doesn't support same-type requirements on generics
public final class SQLConnection<C: SQLClient>: _SQLConnection where C.RowStateSequence.Iterator.Element == C.RowState {
    public typealias Client = C
    public var state: Client.ConnectionState
    
    init(state: Client.ConnectionState) {
        self.state = state
    }
    
    /// Executes the indicated statement, returning nothing.
    /// 
    /// -SeeAlso: `execute(_:returningIDs:as:)`
    public func execute(_ statement: SQLStatement) throws {
        try Client.execute(statement, for: state)
    }
    
    /// Executes the indicated statement, returning the IDs of the rows created by 
    /// it.
    /// 
    /// -Note: To receive the IDs, pass the ID column's name in the `idColumnName`
    ///          parameter and its type in the `idType` parameter. There is no 
    ///          standard SQL mechanism to retrieve values from newly inserted rows, 
    ///          so the client will use database-specific features to do so. These 
    ///          features might not actually use the `idColumnName`, and they might 
    ///          only work on AUTOINCREMENT (or similar) columns.
    public func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type) throws -> AnySequence<Value> {
        return try Client.execute(statement, returningIDs: idColumnName, as: idType, for: state)
    }
    
    fileprivate func makeQueryState(_ statement: SQLStatement) throws -> Client.QueryState {
        return try Client.makeQueryState(statement, for: state)
    }
}

extension SQLConnection where C.RowStateSequence: RandomAccessCollection {
    /// Executes the indicated statement, returning a `Sequence` of rows returned by  
    /// the query. See `SQLQuery` for details on the return value.
    /// 
    /// -Note: Depending on the interface provided by the client, a `SQLQuery` may 
    ///          actually be a `Collection`, `BidirectionalCollection`, or 
    ///          `RandomAccessCollection`. Unless you know your client supports 
    ///          `Collection` or greater, a `SQLQuery` should be treated as though 
    ///          it can only be iterated once.
    public func query(_ statement: SQLStatement) throws -> SQLQueryRandomAccessCollection<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}

extension SQLConnection where C.RowStateSequence: BidirectionalCollection {
    /// Executes the indicated statement, returning a `Sequence` of rows returned by  
    /// the query. See `SQLQuery` for details on the return value.
    /// 
    /// -Note: Depending on the interface provided by the client, a `SQLQuery` may 
    ///          actually be a `Collection`, `BidirectionalCollection`, or 
    ///          `RandomAccessCollection`. Unless you know your client supports 
    ///          `Collection` or greater, a `SQLQuery` should be treated as though 
    ///          it can only be iterated once.
    public func query(_ statement: SQLStatement) throws -> SQLQueryBidirectionalCollection<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}

extension SQLConnection where C.RowStateSequence: Collection {
    /// Executes the indicated statement, returning a `Sequence` of rows returned by  
    /// the query. See `SQLQuery` for details on the return value.
    /// 
    /// -Note: Depending on the interface provided by the client, a `SQLQuery` may 
    ///          actually be a `Collection`, `BidirectionalCollection`, or 
    ///          `RandomAccessCollection`. Unless you know your client supports 
    ///          `Collection` or greater, a `SQLQuery` should be treated as though 
    ///          it can only be iterated once.
    public func query(_ statement: SQLStatement) throws -> SQLQueryCollection<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}

extension SQLConnection where C.RowStateSequence: Sequence {
    /// Executes the indicated statement, returning a `Sequence` of rows returned by  
    /// the query. See `SQLQuery` for details on the return value.
    /// 
    /// -Note: Depending on the interface provided by the client, a `SQLQuery` may 
    ///          actually be a `Collection`, `BidirectionalCollection`, or 
    ///          `RandomAccessCollection`. Unless you know your client supports 
    ///          `Collection` or greater, a `SQLQuery` should be treated as though 
    ///          it can only be iterated once.
    public func query(_ statement: SQLStatement) throws -> SQLQuery<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}
