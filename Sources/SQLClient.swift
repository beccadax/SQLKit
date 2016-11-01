//
//  SQLClient.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

public protocol SQLClient: _SQLClient {
    associatedtype DatabaseState
    associatedtype ConnectionState
    associatedtype QueryState
    // WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
    associatedtype RowStateSequence: Sequence /* where Iterator.Element == RowState */
    associatedtype RowState
    
    static func supports(_ scheme: URL) -> Bool
    
    static func makeDatabaseState(url: URL) -> DatabaseState
    
    static func makeConnectionState(for databaseState: DatabaseState) throws -> ConnectionState
    
    static func execute(_ statement: SQLStatement, for connectionState: ConnectionState) throws
    static func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type, for connectionState: ConnectionState) throws -> AnySequence<Value>
    static func makeQueryState(_ statement: SQLStatement, for connectionState: ConnectionState) throws -> QueryState
    
    static func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type, for queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value>
    static func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type, for queryState: QueryState, statement: SQLStatement) throws -> SQLColumnKey<Value>
    static func count(for queryState: QueryState) -> Int
    static func makeRowStateSequence(for queryState: QueryState) -> RowStateSequence
    
    static func value<Value: SQLValue>(for key: SQLColumnKey<Value>, for rowState: RowState, statement: SQLStatement) throws -> Value
}
