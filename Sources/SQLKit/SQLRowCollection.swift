//
//  SQLRowCollection.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/4/16.
//
//

/// Contains the rows returned by a query.
/// 
/// Like all collections, `SQLRowCollection` is multi-pass—you can iterate through 
/// it several times and return to an earlier row by remembering its index. 
/// Depending on the client, you may also be able to walk backwards or skip rows 
/// using the methods of the `BidirectionalCollection` and `RandomAccessCollection` 
/// protocols.
/// 
/// The index used for this collection is determined by the SQL client. In some 
/// cases it may be an `Int`, but in others it may be an opaque value. In all 
/// cases, however, you can use the `index(after:)` and, depending on 
/// conformances, `index(before:)` and `index(_:offsetBy:)` methods to manipulate 
/// indices.
// 
// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public struct SQLRowCollection<Client: SQLClient>: Collection where Client.RowStateSequence: Collection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public let rowStates: Client.RowStateSequence
    public let statement: SQLStatement

    public var startIndex: Client.RowStateSequence.Index {
        return rowStates.startIndex
    }

    public var endIndex: Client.RowStateSequence.Index {
        return rowStates.endIndex
    }

    public func index(after i: Client.RowStateSequence.Index) -> Client.RowStateSequence.Index {
        return rowStates.index(after: i)
    }

    public subscript(i: Client.RowStateSequence.Index) -> SQLRow<Client> {
        return SQLRow(statement: statement, state: rowStates[i])
    }

    public func distance(from start: Client.RowStateSequence.Index, to end: Client.RowStateSequence.Index) -> Int {
        return rowStates.distance(from: start, to: end)
    }
}

extension SQLRowCollection: BidirectionalCollection where Client.RowStateSequence: BidirectionalCollection {
    public func index(before i: Client.RowStateSequence.Index) -> Client.RowStateSequence.Index {
        return rowStates.index(before: i)
    }
}

extension SQLRowCollection: RandomAccessCollection where Client.RowStateSequence: RandomAccessCollection {
    public func index(_ i: Client.RowStateSequence.Index, offsetBy n: Int) -> Client.RowStateSequence.Index {
        return rowStates.index(i, offsetBy: n)
    }
}

@available(*, deprecated, renamed: "SQLRowCollection")
public typealias SQLRowBidirectionalCollection<Client: SQLClient> = SQLRowCollection<Client> where Client.RowStateSequence: BidirectionalCollection, Client.RowStateSequence.Iterator.Element == Client.RowState

@available(*, deprecated, renamed: "SQLRowCollection")
public typealias SQLRowRandomAccessCollection<Client: SQLClient> = SQLRowCollection<Client> where Client.RowStateSequence: RandomAccessCollection, Client.RowStateSequence.Iterator.Element == Client.RowState
