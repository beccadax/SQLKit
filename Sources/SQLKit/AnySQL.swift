//
//  AnySQL.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

/// An abstract `SQLClient` which can represent any client. `AnySQL` is useful when 
/// you want to support multiple SQL clients with the same piece of code, and 
/// especially when you want to select a client dynamically based on the database 
/// URL.
/// 
/// To use `AnySQL`, you must first register the supported SQL clients with the 
/// `AnySQL` client; then you create a database using `SQLDatabase.init(url:)` and 
/// proceed normally:
/// 
///     AnySQL.register(MySQL.self)
///     AnySQL.register(PostgreSQL.self)
///     AnySQL.register(SQLite.self)
///     
///     let db = SQLDatabase<AnySQL>(url: url)
public enum AnySQL {
    private static var registeredClients: [_SQLClient.Type] = []
    
    /// Adds a `SQLClient` to the list of clients considered by `AnySQL` during 
    /// initialization.
    /// 
    /// `AnySQL` considers registered clients in the opposite order of when they 
    /// were registered; that is, it considers the most recently registered client 
    /// first. It selects the first registered client which says it supports the 
    /// indicated URL.
    public static func register<Client: SQLClient>(_ client: Client.Type) {
        registeredClients.append(client)
    }
    
    private static func indexOfRegisteredClient(supporting url: URL) -> Int? {
        return registeredClients.lastIndex { $0.supports(url) }
    }
    
    /// Returns `true` if any registered SQL client supports the indicated URL.
    public static func supports(_ url: URL) -> Bool {
        return indexOfRegisteredClient(supporting: url) == nil
    }
    
    public static func makeDatabaseState(url: URL) -> DatabaseState {
        let i = indexOfRegisteredClient(supporting: url)!
        let client = registeredClients[i]
        return client.makeDatabaseState(url: url)
    }
}

extension AnySQL: SQLClient {
    /// A type used by `AnySQL` to represent its various State instances.
    public struct State {
        fileprivate var client: _SQLClient.Type
        public var base: Any
    }
    
    /// Sequence of rows produced by a `SQLQuery<AnySQL>`.
    public struct RowStateSequence: Sequence {
        fileprivate var client: _SQLClient.Type
        public var base: AnySequence<Any>
        
        public func makeIterator() -> Iterator {
            return Iterator(client: client, base: base.makeIterator())
        }
        
        public struct Iterator: IteratorProtocol {
            fileprivate var client: _SQLClient.Type
            var base: AnyIterator<Any>
            
            public mutating func next() -> State? {
                return base.next().map { State(client: client, base: $0) }
            }
        }
    }
    
    public typealias DatabaseState = State
    public typealias ConnectionState = State
    public typealias QueryState = State
    public typealias RowState = State
    
    public static func makeConnectionState(for databaseState: DatabaseState) throws -> ConnectionState {
        return try databaseState.client.makeConnectionState(for: databaseState)
    }
    
    public static func execute(_ statement: SQLStatement, for connectionState: ConnectionState) throws {
        try connectionState.client.execute(statement, for: connectionState)
    }
    
    public static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: State) throws -> AnySequence<Value> {
        return try connectionState.client.execute(statement, returningIDs: idColumnName, as: idType, for: connectionState)
    }
    
    public static func makeQueryState(_ statement: SQLStatement, for connectionState: State) throws -> QueryState {
        return try connectionState.client.makeQueryState(statement, for: connectionState)
    }
    
    public static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: State, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        return try queryState.client.columnKey(forName: name, as: valueType, for: queryState, statement: statement)
    }
    
    public static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: State, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        return try queryState.client.columnKey(at: index, as: valueType, for: queryState, statement: statement)
    }
    
    public static func count(for queryState: State) -> Int {
        return queryState.client.count(for: queryState)
    }
    
    public static func makeRowStateSequence(for queryState: State) -> RowStateSequence {
        return queryState.client.makeRowStateSequence(for: queryState)
    }
    
    public static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: State, statement: SQLStatement) throws -> Value {
        return try rowState.client.value(for: key, for: rowState, statement: statement)
    }
}

/// Implementation detail used to implement `AnySQL`. Do not use.
public protocol _SQLClient {
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func supports(_ url: URL) -> Bool
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeDatabaseState(url: URL) -> AnySQL.State
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeConnectionState(for databaseState: AnySQL.State) throws -> AnySQL.State
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute(_ statement: SQLStatement, for connectionState: AnySQL.State) throws
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: AnySQL.State) throws -> AnySequence<Value>
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeQueryState(_ statement: SQLStatement, for connectionState: AnySQL.State) throws -> AnySQL.State
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: AnySQL.State, statement: SQLStatement) throws -> SQLColumnKey<Value>
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: AnySQL.State, statement: SQLStatement) throws -> SQLColumnKey<Value>
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func count(for queryState: AnySQL.State) -> Int
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeRowStateSequence(for queryState: AnySQL.State) -> AnySQL.RowStateSequence
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: AnySQL.State, statement: SQLStatement) throws -> Value
}

public extension _SQLClient where Self: SQLClient {
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeDatabaseState(url: URL) -> AnySQL.State {
        let databaseState: DatabaseState = makeDatabaseState(url: url)
        return AnySQL.State(client: self, base: databaseState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeConnectionState(for databaseState: AnySQL.State) throws -> AnySQL.State {
        let realDatabaseState = databaseState.base as! DatabaseState
        let connectionState = try makeConnectionState(for: realDatabaseState)
        return AnySQL.State(client: self, base: connectionState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute(_ statement: SQLStatement, for connectionState: AnySQL.State) throws {
        let realConnectionState = connectionState.base as! ConnectionState
        try execute(statement, for: realConnectionState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: AnySQL.State) throws -> AnySequence<Value> {
        let realConnectionState = connectionState.base as! ConnectionState
        return try execute(statement, returningIDs: idColumnName, as: idType, for: realConnectionState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeQueryState(_ statement: SQLStatement, for connectionState: AnySQL.State) throws -> AnySQL.State {
        let realConnectionState = connectionState.base as! ConnectionState
        let queryState = try makeQueryState(statement, for: realConnectionState)
        return AnySQL.State(client: self, base: queryState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: AnySQL.State, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        let realQueryState = queryState.base as! QueryState
        return try columnKey(forName: name, as: valueType, for: realQueryState, statement: statement)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: AnySQL.State, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        let realQueryState = queryState.base as! QueryState
        return try columnKey(at: index, as: valueType, for: realQueryState, statement: statement)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func count(for queryState: AnySQL.State) -> Int {
        let realQueryState = queryState.base as! QueryState
        return count(for: realQueryState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeRowStateSequence(for queryState: AnySQL.State) -> AnySQL.RowStateSequence {
        let realQueryState = queryState.base as! QueryState
        let sequence = makeRowStateSequence(for: realQueryState)
        let anySequence = AnySequence<Any>(sequence.lazy.map { $0 as Any })
        
        return AnySQL.RowStateSequence(client: self, base: anySequence)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: AnySQL.State, statement: SQLStatement) throws -> Value {
        let realRowState = rowState.base as! RowState
        return try value(for: key, for: realRowState, statement: statement)
    }
}
