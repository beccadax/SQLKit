//
//  SQLQuery.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/30/16.
//
//

import Foundation

/// Protocol used purely for internal code sharing, and public because of language 
/// limitations. No user-serviceable parts inside.
// 
// WORKAROUND: #3 Swift doesn't support conditional conformance
// WORKAROUND: #4 Swift won't allow protocol extension methods to be more public than the protocol
public protocol _SQLQuery: Sequence {
    associatedtype Client: SQLClient
    
    var statement: SQLStatement { get }
    var state: Client.QueryState { get }
    var rowStates: Client.RowStateSequence { get }
}

extension _SQLQuery {
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
}

extension _SQLQuery {
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

// WORKAROUND: #3 Swift doesn't support conditional conformance
extension _SQLQuery where Self: Sequence {
    /// Returns the only row in the result set. Throws if there are no rows or more 
    /// than one row.
    public func only() throws -> Iterator.Element {
        switch count {
        case 0:
            throw SQLError.noRecordsFound(statement: statement)
        case 1:
            var iterator = makeIterator()
            return iterator.next()!
        default:
            throw SQLError.extraRecordsFound(statement: statement)
        }
    }
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
// WORKAROUND: #3 Swift doesn't support conditional conformance
extension _SQLQuery where Self: Collection, Client.RowStateSequence: Collection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public typealias Index = Client.RowStateSequence.Index
    
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
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
extension _SQLQuery where Self: BidirectionalCollection, Client.RowStateSequence: BidirectionalCollection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public func index(before i: Client.RowStateSequence.Index) -> Client.RowStateSequence.Index {
        return rowStates.index(before: i)
    }
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
extension _SQLQuery where Self: RandomAccessCollection, Client.RowStateSequence: RandomAccessCollection, Client.RowStateSequence.Iterator.Element == Client.RowState {
    public func index(_ i: Client.RowStateSequence.Index, offsetBy n: Client.RowStateSequence.IndexDistance) -> Client.RowStateSequence.Index {
        return rowStates.index(i, offsetBy: n)
    }
}

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
// WORKAROUND: #3 Swift doesn't support conditional conformance
public struct SQLQueryRandomAccessCollection<C: SQLClient>: _SQLQuery, RandomAccessCollection where C.RowStateSequence: RandomAccessCollection, C.RowStateSequence.Iterator.Element == C.RowState {
    public typealias Client = C
    
    /// The statement executed to create this query.
    public let statement: SQLStatement
    /// The state object backing this instance. State objects are client-specific, 
    /// and some clients may expose low-level data structures through the state 
    /// object.
    public var state: Client.QueryState
    /// The sequence of state objects which will be used to create the `SQLRow`s 
    /// returned by iterating over the query.
    public var rowStates: Client.RowStateSequence
    
    init(statement: SQLStatement, state: Client.QueryState) {
        self.statement = statement
        self.state = state
        self.rowStates = Client.makeRowStateSequence(for: state)
    }
}

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
// WORKAROUND: #3 Swift doesn't support conditional conformance
public struct SQLQueryBidirectionalCollection<C: SQLClient>: _SQLQuery, BidirectionalCollection where C.RowStateSequence: BidirectionalCollection, C.RowStateSequence.Iterator.Element == C.RowState {
    public typealias Client = C
    
    /// The statement executed to create this query.
    public let statement: SQLStatement
    /// The state object backing this instance. State objects are client-specific, 
    /// and some clients may expose low-level data structures through the state 
    /// object.
    public var state: Client.QueryState
    /// The sequence of state objects which will be used to create the `SQLRow`s 
    /// returned by iterating over the query.
    public var rowStates: Client.RowStateSequence
    
    init(statement: SQLStatement, state: Client.QueryState) {
        self.statement = statement
        self.state = state
        self.rowStates = Client.makeRowStateSequence(for: state)
    }
}

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
// WORKAROUND: #3 Swift doesn't support conditional conformance
public struct SQLQueryCollection<C: SQLClient>: _SQLQuery, Collection where C.RowStateSequence: Collection, C.RowStateSequence.Iterator.Element == C.RowState {
    public typealias Client = C
    
    /// The statement executed to create this query.
    public let statement: SQLStatement
    /// The state object backing this instance. State objects are client-specific, 
    /// and some clients may expose low-level data structures through the state 
    /// object.
    public var state: Client.QueryState
    /// The sequence of state objects which will be used to create the `SQLRow`s 
    /// returned by iterating over the query.
    public var rowStates: Client.RowStateSequence
    
    init(statement: SQLStatement, state: Client.QueryState) {
        self.statement = statement
        self.state = state
        self.rowStates = Client.makeRowStateSequence(for: state)
    }
}

// WORKAROUND: #1 Swift doesn't support `where` clauses on associated types
public struct SQLRowIterator<Client: SQLClient>: IteratorProtocol where Client.RowStateSequence.Iterator.Element == Client.RowState {
    fileprivate var statement: SQLStatement
    fileprivate var rowStateIterator: Client.RowStateSequence.Iterator
    
    public mutating func next() -> SQLRow<Client>? {
        return rowStateIterator.next().map { SQLRow(statement: statement, state: $0) }
    }
}

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
public struct SQLQuery<C: SQLClient>: _SQLQuery, Sequence where C.RowStateSequence.Iterator.Element == C.RowState {
    public typealias Client = C
    
    /// The statement executed to create this query.
    public let statement: SQLStatement
    /// The state object backing this instance. State objects are client-specific, 
    /// and some clients may expose low-level data structures through the state 
    /// object.
    public var state: Client.QueryState
    /// The sequence of state objects which will be used to create the `SQLRow`s 
    /// returned by iterating over the query.
    public var rowStates: Client.RowStateSequence
    
    init(statement: SQLStatement, state: Client.QueryState) {
        self.statement = statement
        self.state = state
        self.rowStates = Client.makeRowStateSequence(for: state)
    }
    
    public func makeIterator() -> SQLRowIterator<Client> {
        return SQLRowIterator(statement: statement, rowStateIterator: rowStates.makeIterator())
    }
}
