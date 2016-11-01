//
//  SQLRow.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

public struct SQLRow<Client: SQLClient> {
    public var statement: SQLStatement
    public var state: Client.RowState
    
    public func value<Value: SQLValue>(for key: SQLColumnKey<Value>) throws -> Value {
        return try Client.value(for: key, for: state, statement: statement)
    }
}

extension SQLRow {
    public func value<Value: SQLValue>(for key: SQLNullableColumnKey<Value>) throws -> Value? {
        let nonnullKey = SQLColumnKey<Value>(index: key.index, name: key.name)
        do {
            return try value(for: nonnullKey)
        }
        catch SQLError.columnNull(AnySQLColumnKey(nonnullKey), statement: statement) {
            return nil
        }
    }
}
