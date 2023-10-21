//
//  SQLQuery.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 10/30/16.
//
//

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
        self.rowStates = Client.makeRowStateSequence(with: state)
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
        return try withErrorsPackaged(in: SQLError.makeColumnInvalid(with: statement, for: .name(name))) {
            guard let index = try Client.columnIndex(forName: name, as: valueType, with: state) else {
                throw SQLColumnError.columnMissing
            }
            return SQLColumnKey(index: index, name: name)
        }
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
        return try withErrorsPackaged(in: SQLError.makeColumnInvalid(with: statement, for: .index(index))) {
            guard let name = try Client.columnName(at: index, as: valueType, with: state) else {
                throw SQLColumnError.columnMissing
            }
            return SQLColumnKey(index: index, name: name)
        }
    }
    
    /// The number of rows returned by the query.
    /// 
    /// - Note: Although normally using `count` consumes a `Sequence`, it does not 
    ///          do so for a `SQLQuery`, so it's safe to call `count` even if the 
    ///          client otherwise doesn't support iterating over a query's rows more 
    ///          than once.
    public var count: Int {
        return Client.count(with: state)
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
        return SQLNullableColumnKey(nonnull)
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
        return SQLNullableColumnKey(nonnull)
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
