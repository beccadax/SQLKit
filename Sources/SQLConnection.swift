//
//  SQLConnection.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

public protocol _SQLConnection {
    associatedtype Client: SQLClient
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public final class SQLConnection<C: SQLClient>: _SQLConnection where C.RowStateSequence.Iterator.Element == C.RowState {
    public typealias Client = C
    public var state: Client.ConnectionState
    
    init(state: Client.ConnectionState) {
        self.state = state
    }
    
    public func execute(_ statement: SQLStatement) throws {
        try Client.execute(statement, for: state)
    }
    
    public func execute<Value: SQLValue>(_ statement: SQLStatement, returningIDs idColumnName: String, as idType: Value.Type) throws -> AnySequence<Value> {
        return try Client.execute(statement, returningIDs: idColumnName, as: idType, for: state)
    }

    
    fileprivate func makeQueryState(_ statement: SQLStatement) throws -> Client.QueryState {
        return try Client.makeQueryState(statement, for: state)
    }
}

extension SQLConnection where C.RowStateSequence: RandomAccessCollection {
    public func query(_ statement: SQLStatement) throws -> SQLQueryRandomAccessCollection<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}

extension SQLConnection where C.RowStateSequence: BidirectionalCollection {
    public func query(_ statement: SQLStatement) throws -> SQLQueryBidirectionalCollection<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}

extension SQLConnection where C.RowStateSequence: Collection {
    public func query(_ statement: SQLStatement) throws -> SQLQueryCollection<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}

extension SQLConnection where C.RowStateSequence: Sequence {
    public func query(_ statement: SQLStatement) throws -> SQLQuerySequence<Client> {
        return .init(statement: statement, state: try makeQueryState(statement))
    }
}
