//
//  AnySQLClient.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

public protocol _SQLClient {
    static func supports(_ url: URL) -> Bool
    static func makeDatabaseState(url: URL) -> AnySQLClient.State
    
    static func makeConnectionState(for databaseState: AnySQLClient.State) throws -> AnySQLClient.State
    
    static func execute(_ statement: SQLStatement, for connectionState: AnySQLClient.State) throws
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: AnySQLClient.State) throws -> AnySequence<Value>
    static func makeQueryState(_ statement: SQLStatement, for connectionState: AnySQLClient.State) throws -> AnySQLClient.State
    
    static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: AnySQLClient.State, statement: SQLStatement) throws -> SQLColumnKey<Value>
    static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: AnySQLClient.State, statement: SQLStatement) throws -> SQLColumnKey<Value>
    static func count(for queryState: AnySQLClient.State) -> Int
    static func makeRowSequence(for queryState: AnySQLClient.State) -> AnySQLClient.QueryRowSequence
    
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: AnySQLClient.State, statement: SQLStatement) throws -> Value
}

public extension _SQLClient where Self: SQLClient {
    static func makeDatabaseState(url: URL) -> AnySQLClient.State {
        let databaseState: DatabaseState = makeDatabaseState(url: url)
        return AnySQLClient.State(client: self, base: databaseState)
    }
    
    static func makeConnectionState(for databaseState: AnySQLClient.State) throws -> AnySQLClient.State {
        let realDatabaseState = databaseState.base as! DatabaseState
        let connectionState = try makeConnectionState(for: realDatabaseState)
        return AnySQLClient.State(client: self, base: connectionState)
    }
    
    static func execute(_ statement: SQLStatement, for connectionState: AnySQLClient.State) throws {
        let realConnectionState = connectionState.base as! ConnectionState
        try execute(statement, for: realConnectionState)
    }
    
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: AnySQLClient.State) throws -> AnySequence<Value> {
        let realConnectionState = connectionState.base as! ConnectionState
        return try execute(statement, returningIDs: idColumnName, as: idType, for: realConnectionState)
    }
    
    static func makeQueryState(_ statement: SQLStatement, for connectionState: AnySQLClient.State) throws -> AnySQLClient.State {
        let realConnectionState = connectionState.base as! ConnectionState
        let queryState = try makeQueryState(statement, for: realConnectionState)
        return AnySQLClient.State(client: self, base: queryState)
    }
    
    static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: AnySQLClient.State, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        let realQueryState = queryState.base as! QueryState
        return try columnKey(forName: name, as: valueType, for: realQueryState, statement: statement)
    }
    
    static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: AnySQLClient.State, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        let realQueryState = queryState.base as! QueryState
        return try columnKey(at: index, as: valueType, for: realQueryState, statement: statement)
    }
    
    static func count(for queryState: AnySQLClient.State) -> Int {
        let realQueryState = queryState.base as! QueryState
        return count(for: realQueryState)
    }
    
    static func makeRowSequence(for queryState: AnySQLClient.State) -> AnySQLClient.QueryRowSequence {
        let realQueryState = queryState.base as! QueryState
        let sequence = makeRowSequence(for: realQueryState)
        let anySequence = AnySequence<Any>(sequence.lazy.map { $0 as Any })
        
        return AnySQLClient.QueryRowSequence(client: self, base: anySequence)
    }
    
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: AnySQLClient.State, statement: SQLStatement) throws -> Value {
        let realRowState = rowState.base as! RowState
        return try value(for: key, for: realRowState, statement: statement)
    }
}

public protocol _AnySQLClient {}

public enum AnySQLClient: _AnySQLClient {
    private static var registeredClients: [_SQLClient.Type] = []
    
    public static func register(_ client: _SQLClient.Type) {
        registeredClients.append(client)
    }
    
    private static func indexOfRegisteredClient(supporting url: URL) -> Int? {
        return registeredClients.lastIndex { $0.supports(url) }
    }
    
    public static func supports(_ url: URL) -> Bool {
        return indexOfRegisteredClient(supporting: url) == nil
    }
    
    public static func makeDatabaseState(url: URL) -> DatabaseState {
        let i = indexOfRegisteredClient(supporting: url)!
        let client = registeredClients[i]
        return client.makeDatabaseState(url: url)
    }
}

extension AnySQLClient: SQLClient {
    public struct State {
        fileprivate var client: _SQLClient.Type
        public var base: Any
    }
    
    public struct QueryRowSequence: Sequence {
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
    
    public static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: AnySQLClient.State) throws -> AnySequence<Value> {
        return try connectionState.client.execute(statement, returningIDs: idColumnName, as: idType, for: connectionState)
    }
    
    public static func makeQueryState(_ statement: SQLStatement, for connectionState: ConnectionState) throws -> QueryState {
        return try connectionState.client.makeQueryState(statement, for: connectionState)
    }
    
    public static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        return try queryState.client.columnKey(forName: name, as: valueType, for: queryState, statement: statement)
    }
    
    public static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value> {
        return try queryState.client.columnKey(at: index, as: valueType, for: queryState, statement: statement)
    }
    
    public static func count(for queryState: QueryState) -> Int {
        return queryState.client.count(for: queryState)
    }
    
    public static func makeRowSequence(for queryState: QueryState) -> QueryRowSequence {
        return queryState.client.makeRowSequence(for: queryState)
    }
    
    public static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: RowState, statement: SQLStatement) throws -> Value {
        return try rowState.client.value(for: key, for: rowState, statement: statement)
    }
}
