//
//  SQLDatabase.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public struct SQLDatabase<Client: SQLClient> where Client.RowStateSequence.Iterator.Element == Client.RowState {
    public static func supports(_ url: URL) -> Bool {
        return Client.supports(url)
    }
    
    public var state: Client.DatabaseState
    public init(url: URL) {
        state = Client.makeDatabaseState(url: url)
    }
    
    public func makeConnection() throws -> SQLConnection<Client> {
        return SQLConnection(state: try Client.makeConnectionState(for: state))
    }
}

extension Pool where Resource: _SQLConnection, Resource.Client.RowStateSequence.Iterator.Element == Resource.Client.RowState {
    public convenience init(database: SQLDatabase<Resource.Client>, maximum: Int = 10, timeout: DispatchTimeInterval = .seconds(10)) {
        self.init(maximum: maximum, timeout: timeout) {
            return try database.makeConnection() as! Resource
        }
    }
}
