//
//  SQLRowIterator.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/4/16.
//
//

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
