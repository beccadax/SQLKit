//
//  PGResultField.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PGResult {
    /// Accesses a `FieldView` describing all of the fields included in this 
    /// result object.
    /// 
    /// `fields` can be used to get the number of fields or access detailed 
    /// information about particular fields. Some examples of use:
    /// 
    ///    result.fields.count
    ///    result.fields[2].name
    ///    result.index(of: "user_id")
    ///    print(result.fields.map { $0.name })
    public var fields: FieldView {
        return FieldView(result: self)
    }
    
    /// Represents a field in a result, describing certain pieces of metadata about 
    /// it.
    /// 
    /// - Warning: The `Field` struct's properties are mostly computed, and rely  
    ///              on the `PGResult` the instance is derived from to access the 
    ///              information. Do not use a `Field` from a `PGResult` which you 
    ///              have already `clear()`ed.
    public struct Field {
        let result: PGResult
        /// The index of the field in each row.
        public let index: Int
        
        /// The type of data in the column, if a type is known.
        /// 
        /// - PreferredOver: `PQftype`
        public var type: PGType? {
            let oid = PQftype(result.pointer, Int32(index))
            return PGType(rawValue: oid)
        }
        
        /// The type modifier of the column's type. This is usually something like 
        /// a precision on a numeric field, but the details vary by type. `nil` if 
        /// there is no type modifier.
        /// 
        /// - PreferredOver: `PQfmod`
        public var typeModifier: Int? {
            let mod = PQfmod(result.pointer, Int32(index))
            if mod == -1 {
                return nil
            }
            return Int(mod)
        }
        
        /// The name of the column.
        /// 
        /// - PreferredOver: `PQfname`
        public var name: String {
            guard let cString = PQfname(result.pointer, Int32(index)) else {
                preconditionFailure("Index out of range")
            }
            return String(cString: cString)
        }
        
        /// The PostgreSQL object identifier of the table which the field came from.  
        /// `nil` if the data doesn't come directly from a table column.
        /// 
        /// - PreferredOver: `PQftable`
        public var table: Oid? {
            let tableID = PQftable(result.pointer, Int32(index))
            
            if tableID == InvalidOid {
                return nil
            }
            return tableID
        }
        
        /// The index of the column in `table` which the field came from.
        /// `nil` if teh data doesn't come directly from a table column.
        /// 
        /// - Warning: Although the equivalent `libpq` functionality is 1-based, this property is zero-based.
        /// 
        /// - PreferredOver: `PQftablecol`
        public var columnIndex: Int? {
            let column = PQftablecol(result.pointer, Int32(index))
            if column == 0 {
                return nil
            }
            return column - 1
        }
        
        /// The format of the raw values returned when accessing this field.
        public var format: PGRawValue.Format {
            let raw = PQfformat(result.pointer, Int32(index))
            return PGRawValue.Format(rawValue: raw)!
        }
    }
    
    /// Represents the set of fields associated with a result.
    /// 
    /// A `FieldView` for a `PGResult` can be accessed through its `fields` 
    /// property. It is an `Int`-indexed `RandomAccessCollection` whose elements 
    /// are all `Field` instances describing individual fields in the result's tuples.
    /// 
    /// As a `RandomAccessCollection`, you can access the number of fields 
    /// through the `count` property and obtain information about a field by 
    /// subscripting the `FieldView`. You can also use the `index(of:)` variant 
    /// which takes a `String` to find a field by name instead of index. You can 
    /// even do more sophisticated operations, such as using `map` on the list of 
    /// fields.
    /// 
    /// - Warning: The `FieldView` struct's properties are mostly computed, and rely  
    ///              on the `PGResult` the instance is derived from to access the 
    ///              information. Do not use a `FieldView` from a `PGResult` which you 
    ///              have already `clear()`ed.
    public struct FieldView: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PGResult
        
        /// The index after the index of the last field.
        /// 
        /// - PreferredOver: `PQnfields`
        public var endIndex: Int {
            return Int(PQnfields(result.pointer))
        }
        
        /// Retrieves information about the `i`th field in the result's fields. 
        public subscript(i: Int) -> Field {
            precondition(i < endIndex, "Index out of bounds")
            return Field(result: result, index: i)
        }
        
        /// Returns the index of the field with the given `name`.
        /// 
        /// - PreferredOver: `PQfnumber`
        public func index(of name: String) -> Int? {
            let i = PQfnumber(result.pointer, name)
            if i == -1 { return nil }
            return Int(i)
        }
        
        public typealias Indices = DefaultRandomAccessIndices<FieldView>
    }
}
