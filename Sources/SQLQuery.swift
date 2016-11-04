//
//  SQLQuery.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

/// Represents the results of a query.
/// 
/// A `SQLQuery` has two purposes. One is to access the instances representing 
/// each row (`SQLRow`) returned by the query. The other is to create the column 
/// keys (`SQLColumnKey`) used to access columns in those rows.
/// 
/// `SQLQuery` is only guaranteed to be a `Sequence`, so you may only be able to 
/// enumerate the rows returned by a query once. However, some clients return a 
/// `Collection`, `BidirectionalCollection`, or `RandomAccessCollection`; if they 
/// do, `SQLQuery` will support those additional protocols.
/// 
/// - Note: Due to language limitations, `Collection`s are handled by variant types, 
///          such as `SQLQueryCollection`. These present identical interfaces to 
///          `SQLQuery`, but add additional conformances.
// 
// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public struct SQLQuery<Client: SQLClient> where Client.RowStateSequence.Iterator.Element == Client.RowState {
    /// The statement executed to create this query.
    public let statement: SQLStatement
    /// The state object backing this instance. State objects are client-specific, 
    /// and some clients may expose low-level data structures through the state 
    /// object.
    public var state: Client.QueryState
    /// The sequence of state objects which will be used to create the `SQLRow`s 
    /// returned by iterating over the query.
    public var rowStates: Client.RowStateSequence
    
    /// Provides access to the rows returned by the query.
    /// 
    /// Like all iterators, `rowIterator` is single-pass—the rows in the sequence 
    /// are consumed as they're read. Unlike most iterators, `rowIterator` is also 
    /// a `Sequence`; it can be used in a `for` loop or with `map(_:)`.
    /// 
    /// Some SQL clients allow you to make multiple passes through the rows or 
    /// move back and forth through them. Queries on clients which support these 
    /// features include a `rows` property.
    /// 
    /// - SeeAlso: `rows`, `onlyRow()`
    public let rowIterator: SQLRowIterator<Client>
    
    /// Returns the only row in the result set.
    /// 
    /// - Throws: If there are no rows or more than one row.
    /// 
    /// - SeeAlso: `rowIterator`, `onlyRow()`
    public func onlyRow() throws -> SQLRow<Client> {
        guard let oneRow = rowIterator.next() else {
            throw SQLError.noRecordsFound(statement: statement)
        }
        
        guard rowIterator.next() == nil else {
            throw SQLError.extraRecordsFound(statement: statement)
        }
        
        return oneRow
    }
    
    init(statement: SQLStatement, state: Client.QueryState) {
        self.statement = statement
        self.state = state
        self.rowStates = Client.makeRowStateSequence(for: state)
        self.rowIterator = SQLRowIterator(statement: statement, rowStateIterator: rowStates.makeIterator())
    }
    
    /// Returns a key for a column with the given name and type.
    /// 
    /// - Parameter name: The name of the column. This may be case-sensitive.
    /// - Parameter valueType: The type of the column's value. Must conform to  
    ///               `SQLValue` or be an `Optional` of a type conforming to 
    ///               `SQLValue`.
    /// 
    /// - Throws: If the column doesn't exist or possibly if it's the wrong type.
    /// 
    /// - Note: If `valueType` is not an `Optional` type, then accessing the column's 
    ///          value will throw an error.
    public func columnKey<Value: SQLValue>(forName name: String, as valueType: Value.Type) throws -> SQLColumnKey<Value> {
        return try Client.columnKey(forName: name, as: valueType, for: state, statement: statement)
    }
    
    /// Returns a key for a column at the given index and with the given type.
    /// 
    /// - Parameter index: The zero-based index of the column in the row.
    /// - Parameter valueType: The type of the column's value. Must conform to  
    ///               `SQLValue` or be an `Optional` of a type conforming to 
    ///               `SQLValue`.
    /// 
    /// - Throws: If the column doesn't exist or possibly if it's the wrong type.
    /// 
    /// - Note: If `valueType` is not an Optional type, then accessing the column's 
    ///          value will throw an error.
    public func columnKey<Value: SQLValue>(at index: Int, as valueType: Value.Type) throws -> SQLColumnKey<Value> {
        return try Client.columnKey(at: index, as: valueType, for: state, statement: statement)
    }
    
    /// The number of rows returned by the query.
    /// 
    /// - Note: Although normally using `count` consumes a `Sequence`, it does not 
    ///          do so for a `SQLQuery`, so it's safe to call `count` even if the 
    ///          client otherwise doesn't support iterating over a query's rows more 
    ///          than once.
    public var count: Int {
        return Client.count(for: state)
    }
    
    /// Returns a key for a column with the given name and type.
    /// 
    /// - Parameter name: The name of the column. This may be case-sensitive.
    /// - Parameter valueType: The type of the column's value. Must conform to  
    ///               `SQLValue` or be an `Optional` of a type conforming to 
    ///               `SQLValue`.
    /// 
    /// - Throws: If the column doesn't exist or possibly if it's the wrong type.
    /// 
    /// - Note: If `valueType` is not an Optional type, then accessing the column's 
    ///          value will throw an error.
    public func columnKey<Value: SQLValue>(forName name: String, as valueType: Value?.Type) throws -> SQLNullableColumnKey<Value> {
        let nonnull = try columnKey(forName: name, as: Value.self)
        return SQLNullableColumnKey(index: nonnull.index, name: nonnull.name)
    }
    
    /// Returns a key for a column at the given index and with the given type.
    /// 
    /// - Parameter index: The zero-based index of the column in the row.
    /// - Parameter valueType: The type of the column's value. Must conform to  
    ///               `SQLValue` or be an `Optional` of a type conforming to 
    ///               `SQLValue`.
    /// 
    /// - Throws: If the column doesn't exist or possibly if it's the wrong type.
    /// 
    /// - Note: If `valueType` is not an Optional type, then accessing the column's 
    ///          value will throw an error.
    public func columnKey<Value: SQLValue>(at index: Int, as valueType: Value?.Type) throws -> SQLNullableColumnKey<Value> {
        let nonnull = try columnKey(at: index, as: Value.self)
        return SQLNullableColumnKey(index: nonnull.index, name: nonnull.name)
    }
}

extension SQLQuery where Client.RowStateSequence: Collection {
    /// The rows returned by the query.
    /// 
    /// `rows` is a `Collection`, so it may be indexed and walked through several 
    /// times. Depending on the client, it may also be a `BidirectionalCollection` 
    /// (allowing walking backwards) or a `RandomAccessCollection` (allowing 
    /// walking to any arbitrary index).
    /// 
    /// If a particular client does not support the `rows` property, you can 
    /// greedily fetch all rows into an array by writing:
    /// 
    ///     let array = Array(myQuery.rowIterator)
    /// 
    /// - SeeAlso: `rowIterator`, `onlyRow()`
    public var rows: SQLRowCollection<Client> {
        return .init(rowStates: rowStates, statement: statement)
    }
}

extension SQLQuery where Client.RowStateSequence: BidirectionalCollection {
    /// The rows returned by the query.
    /// 
    /// `rows` is a `Collection`, so it may be indexed and walked through several 
    /// times. Depending on the client, it may also be a `BidirectionalCollection` 
    /// (allowing walking backwards) or a `RandomAccessCollection` (allowing 
    /// walking to any arbitrary index).
    /// 
    /// If a particular client does not support the `rows` property, you can 
    /// greedily fetch all rows into an array by writing:
    /// 
    ///     let array = Array(myQuery.rowIterator)
    /// 
    /// - SeeAlso: `rowIterator`, `onlyRow()`
    public var rows: SQLRowBidirectionalCollection<Client> {
        return .init(rowStates: rowStates, statement: statement)
    }
}

extension SQLQuery where Client.RowStateSequence: RandomAccessCollection {
    /// The rows returned by the query.
    /// 
    /// `rows` is a `Collection`, so it may be indexed and walked through several 
    /// times. Depending on the client, it may also be a `BidirectionalCollection` 
    /// (allowing walking backwards) or a `RandomAccessCollection` (allowing 
    /// walking to any arbitrary index).
    /// 
    /// If a particular client does not support the `rows` property, you can 
    /// greedily fetch all rows into an array by writing:
    /// 
    ///     let array = Array(myQuery.rowIterator)
    /// 
    /// - SeeAlso: `rowIterator`, `onlyRow()`
    public var rows: SQLRowRandomAccessCollection<Client> {
        return .init(rowStates: rowStates, statement: statement)
    }
}

/// An iterator which walks through the rows returned by the query.
/// 
/// Like all iterators, `SQLRowIterator` is single-pass—the rows in the sequence 
/// are consumed as they're read. Unlike most iterators, `SQLRowIterator` is also 
/// a `Sequence`; it can be used in a `for` loop or with `map(_:)`.
/// 
/// Some SQL clients support multi-pass access to the rows returned by a query. 
/// See `SQLQuery` and its `rows` collection for that.
// 
// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public final class SQLRowIterator<Client: SQLClient>: Sequence, IteratorProtocol where Client.RowStateSequence.Iterator.Element == Client.RowState {
    fileprivate var statement: SQLStatement
    fileprivate var rowStateIterator: Client.RowStateSequence.Iterator
    
    init(statement: SQLStatement, rowStateIterator: Client.RowStateSequence.Iterator) {
        self.statement = statement
        self.rowStateIterator = rowStateIterator
    }
        
    public func next() -> SQLRow<Client>? {
        return rowStateIterator.next().map { SQLRow(statement: statement, state: $0) }
    }
}

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
