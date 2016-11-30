//
//  SQLDatabase.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation

/// An abstract representation of a potential source of SQL data. A SQLDatabase 
/// instance contains the information needed to connect to a SQL database. Use its 
/// `makeConnection()` method to actually connect.
/// 
/// A `SQLDatabase` uses a particular client—a database library backed by 
/// a specific type conforming to `SQLClient`—indicated by `SQLDatabase`'s 
/// generic parameter. That means the type of database is part of the compile-time 
/// type of the variable. If you want to support multiple database types without 
/// using generics, see the `AnySQL` client.
// 
// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public struct SQLDatabase<Client: SQLClient> where Client.RowStateSequence.Iterator.Element == Client.RowState {
    /// Returns `true` if this type of database is designed to connect to `url`.
    /// 
    /// `supports(_:)` may return `true` even if the database cannot be reached, 
    /// doesn't exist, or `url` is ill-formed. What this method indicates is that, 
    /// *if* `url` is to work with any type, it ought to work with this type. 
    /// If a connection error occurs, it will be indicated by `makeConnection()` 
    /// throwing an error.
    /// 
    /// - SeeAlso: `SQLDatabase.init(url:)`, `SQLDatabase.makeConnection()`
    public static func supports(_ url: URL) -> Bool {
        return Client.supports(url)
    }
    
    /// The state object backing this instance. State objects are client-specific, 
    /// and some clients may expose low-level data structures through the state 
    /// object.
    public var state: Client.DatabaseState
    
    /// Creates a new instance which represents the database at the indicated URL.
    /// 
    /// - Parameter url: The URL at which the database can be accessed.
    ///
    /// - Precondition: `url` is valid for this database's SQL client. If you're not 
    ///                  sure a URL will be supported, use the `supports(_:)` class 
    ///                  method to check before using this initializer. 
    public init(url: URL) {
        state = Client.makeDatabaseState(url: url)
    }
    
    /// Create a connection to this database.
    /// 
    /// - SeeAlso: `Pool`, which can be used to make connection pools.
    public func makeConnection() throws -> SQLConnection<Client> {
        let connectonState = try withErrorsPackaged(in: SQLError.connectionFailed) {
            try Client.makeConnectionState(with: state)
        }
        return SQLConnection(state: connectonState)
    }
}

// WORKAROUND: #2 Swift doesn't support same-type requirements on generics
extension Pool where Resource: _SQLConnection, Resource.Client.RowStateSequence.Iterator.Element == Resource.Client.RowState {
    /// Creates a pool of connections to the given database.
    /// 
    /// - Parameter database: The database to connect to.
    /// - Parameter maximum: The maximum number of database connections to use.
    ///                          Default: 10.
    /// - Parameter timeout: The maximum amount of time to wait for a connection 
    ///                         to be returned to the pool. Default: 10 seconds.
    public convenience init(database: SQLDatabase<Resource.Client>, maximum: Int = 10, timeout: DispatchTimeInterval = .seconds(10)) {
        self.init(maximum: maximum, timeout: timeout) {
            return try database.makeConnection() as! Resource
        }
    }
}
