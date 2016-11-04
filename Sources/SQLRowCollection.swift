//
//  SQLRowCollection.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/4/16.
//
//

/// Protocol used purely for internal code sharing, and public because of language 
/// limitations. No user-serviceable parts inside.
// 
// WORKAROUND: #3 Swift doesn't support conditional conformance
// WORKAROUND: #4 Swift won't allow protocol extension methods to be more public than the protocol
public protocol _SQLRowCollection {
    associatedtype _Client: SQLClient
    
    var rowStates: _Client.RowStateSequence { get }
    var statement: SQLStatement { get }
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
extension _SQLRowCollection where _Client.RowStateSequence: Collection, _Client.RowStateSequence.Iterator.Element == _Client.RowState {
    public typealias Index = _Client.RowStateSequence.Index
    
    public var startIndex: _Client.RowStateSequence.Index {
        return rowStates.startIndex
    }
    
    public var endIndex: _Client.RowStateSequence.Index {
        return rowStates.endIndex
    }
    
    public func index(after i: _Client.RowStateSequence.Index) -> _Client.RowStateSequence.Index {
        return rowStates.index(after: i)
    }
    
    public subscript(i: _Client.RowStateSequence.Index) -> SQLRow<_Client> {
        return SQLRow(statement: statement, state: rowStates[i])
    }
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
extension _SQLRowCollection where _Client.RowStateSequence: BidirectionalCollection, _Client.RowStateSequence.Iterator.Element == _Client.RowState {
    public func index(before i: _Client.RowStateSequence.Index) -> _Client.RowStateSequence.Index {
        return rowStates.index(before: i)
    }
}

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
public struct SQLRowCollection<Client: SQLClient>: _SQLRowCollection, Collection where Client.RowStateSequence: Collection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public typealias _Client = Client
    public let rowStates: Client.RowStateSequence
    public let statement: SQLStatement
}

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
// WORKAROUND: #3 Swift doesn't support conditional conformance
public struct SQLRowBidirectionalCollection<Client: SQLClient>: _SQLRowCollection, BidirectionalCollection where Client.RowStateSequence: BidirectionalCollection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public typealias _Client = Client
    public let rowStates: Client.RowStateSequence
    public let statement: SQLStatement
}

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
// WORKAROUND: #3 Swift doesn't support conditional conformance
public struct SQLRowRandomAccessCollection<Client: SQLClient>: _SQLRowCollection, RandomAccessCollection where Client.RowStateSequence: RandomAccessCollection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public typealias _Client = Client
    public let rowStates: Client.RowStateSequence
    public let statement: SQLStatement
    
    public func index(_ i: _Client.RowStateSequence.Index, offsetBy n: _Client.RowStateSequence.IndexDistance) -> _Client.RowStateSequence.Index {
        return rowStates.index(i, offsetBy: n)
    }
}
