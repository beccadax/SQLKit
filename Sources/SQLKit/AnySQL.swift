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
/// 
/// The most recently registered clients take priority, so you can always 
/// re-register a client to move it up the list.
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
    
    public static func makeConnectionState(with databaseState: DatabaseState) throws -> ConnectionState {
        return try databaseState.client.makeConnectionState(with: databaseState)
    }
    
    public static func execute(_ statement: SQLStatement, with connectionState: ConnectionState) throws {
        try connectionState.client.execute(statement, with: connectionState)
    }
    
    public static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, with connectionState: State) throws -> AnySequence<Value> {
        return try connectionState.client.execute(statement, returningIDs: idColumnName, as: idType, with: connectionState)
    }
    
    public static func makeQueryState(_ statement: SQLStatement, with connectionState: State) throws -> QueryState {
        return try connectionState.client.makeQueryState(statement, with: connectionState)
    }
    
    public static func columnIndex<Value: SQLValue>(forName name: String, as valueType: Value.Type, with queryState: State) throws -> Int? {
        return try queryState.client.columnIndex(forName: name, as: valueType, with: queryState)
    }
    
    public static func columnName<Value: SQLValue>(at index: Int, as valueType: Value.Type, with queryState: State) throws -> String? {
        return try queryState.client.columnName(at: index, as: valueType, with: queryState)
    }
    
    public static func count(with queryState: State) -> Int {
        return queryState.client.count(with: queryState)
    }
    
    public static func makeRowStateSequence(with queryState: State) -> RowStateSequence {
        return queryState.client.makeRowStateSequence(with: queryState)
    }
    
    public static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, with rowState: State) throws -> Value? {
        return try rowState.client.value(for: key, with: rowState)
    }
}

/// Implementation detail used to implement `AnySQL`. Do not use.
public protocol _SQLClient {
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func supports(_ url: URL) -> Bool
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeDatabaseState(url: URL) -> AnySQL.State
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeConnectionState(with databaseState: AnySQL.State) throws -> AnySQL.State
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute(_ statement: SQLStatement, with connectionState: AnySQL.State) throws
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, with connectionState: AnySQL.State) throws -> AnySequence<Value>
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeQueryState(_ statement: SQLStatement, with connectionState: AnySQL.State) throws -> AnySQL.State
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnIndex<Value: SQLValue>(forName name: String, as valueType: Value.Type, with queryState: AnySQL.State) throws -> Int?
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnName<Value: SQLValue>(at index: Int, as valueType: Value.Type, with queryState: AnySQL.State) throws -> String?
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func count(with queryState: AnySQL.State) -> Int
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeRowStateSequence(with queryState: AnySQL.State) -> AnySQL.RowStateSequence
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, with rowState: AnySQL.State) throws -> Value?
}

public extension _SQLClient where Self: SQLClient {
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeDatabaseState(url: URL) -> AnySQL.State {
        let databaseState: DatabaseState = makeDatabaseState(url: url)
        return AnySQL.State(client: self, base: databaseState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeConnectionState(with databaseState: AnySQL.State) throws -> AnySQL.State {
        let realDatabaseState = databaseState.base as! DatabaseState
        let connectionState = try makeConnectionState(with: realDatabaseState)
        return AnySQL.State(client: self, base: connectionState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute(_ statement: SQLStatement, with connectionState: AnySQL.State) throws {
        let realConnectionState = connectionState.base as! ConnectionState
        try execute(statement, with: realConnectionState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, with connectionState: AnySQL.State) throws -> AnySequence<Value> {
        let realConnectionState = connectionState.base as! ConnectionState
        return try execute(statement, returningIDs: idColumnName, as: idType, with: realConnectionState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeQueryState(_ statement: SQLStatement, with connectionState: AnySQL.State) throws -> AnySQL.State {
        let realConnectionState = connectionState.base as! ConnectionState
        let queryState = try makeQueryState(statement, with: realConnectionState)
        return AnySQL.State(client: self, base: queryState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnIndex<Value: SQLValue>(forName name: String, as valueType: Value.Type, with queryState: AnySQL.State) throws -> Int? {
        let realQueryState = queryState.base as! QueryState
        return try columnIndex(forName: name, as: valueType, with: realQueryState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func columnName<Value: SQLValue>(at index: Int, as valueType: Value.Type, with queryState: AnySQL.State) throws -> String? {
        let realQueryState = queryState.base as! QueryState
        return try columnName(at: index, as: valueType, with: realQueryState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func count(with queryState: AnySQL.State) -> Int {
        let realQueryState = queryState.base as! QueryState
        return count(with: realQueryState)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func makeRowStateSequence(with queryState: AnySQL.State) -> AnySQL.RowStateSequence {
        let realQueryState = queryState.base as! QueryState
        let sequence = makeRowStateSequence(with: realQueryState)
        let anySequence = AnySequence<Any>(sequence.lazy.map { $0 as Any })
        
        return AnySQL.RowStateSequence(client: self, base: anySequence)
    }
    
    /// Implementation detail used to implement `AnySQL`. Do not use.
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, with rowState: AnySQL.State) throws -> Value? {
        let realRowState = rowState.base as! RowState
        return try value(for: key, with: realRowState)
    }
}
