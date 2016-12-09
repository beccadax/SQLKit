//
//  PGResultTuple.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PGResult {
    /// Accesses a `TupleView` describing all of the tuples included in this result 
    /// object.
    /// 
    /// The tuples are the actual "rows" of data returned by the query. `tuples` 
    /// can be used to get the number of tuples or access individual tuples to get 
    /// the values of their fields. Some examples of use:
    /// 
    ///     result.tuples.count
    ///     try result.tuples[2].value(for: "user_id", as: Int.self)
    ///     for result.tuples { … }
    ///     print(result.tuples.map { $0.value(in: someField, as: String.self) })
    public var tuples: TupleView {
        return TupleView(result: self)
    }
    
    /// Represents a tuple or "row" of data in a result.
    /// 
    /// `Tuple` is an `Int`-indexed `RandomAccessCollection`, but when using 
    /// its subscripts it returns `PGRawValue?`s which must be converted to 
    /// something usable. It is typically more useful to use the `value(in:as:)`, 
    /// `value(at:as:)`, or `value(for:as:)` methods to convert the value 
    /// into a usable `PGValue`-conforming type.
    /// 
    /// - Warning: The `Tuple` struct's properties and subscripts rely  
    ///              on the `PGResult` the instance is derived from to access the 
    ///              information. Do not use a `Tuple` from a `PGResult` which you 
    ///              have already `clear()`ed.
    public struct Tuple: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PGResult
        /// The index of the tuple in the result's `tuples` collection.
        public let index: Int
        
        /// The index after the index of the last field.
        /// 
        /// - RecommendedOver: `PQnfields`
        public var endIndex: Int {
            return result.fields.endIndex
        }
        
        /// Accesses the raw value of `field` in this tuple, or `nil` if the field is 
        /// `NULL`.
        /// 
        /// The returned `PGRawValue` will be binary if `field.format` is `binary`,
        /// or textual if `field.format` is textual. This is usually determined by the 
        /// `resultFormat` parameter on the various `execute(…)` methods, which 
        /// defaults to `textual`.
        /// 
        /// This subscript returns a `PGRawValue`, which will require additional 
        /// processing to form a usable value. It's usually better to use the 
        /// `value(in:as:)` method, which immediately constructs a 
        /// `PGValue`-conforming type from the value.
        /// 
        /// - Precondition: `field` is a `Field` from the same `PGResult` used to 
        ///                   access the `Tuple`.
        /// 
        /// - Recommended: `PGResult.Tuple.value(in:as:)`
        /// - RecommendedOver: `PQgetvalue`, `PQgetisnull`, `PQgetlength`
        public subscript(field: Field) -> PGRawValue? {
            precondition(field.result === result, "Used a Field from one Result to access a Tuple from another Result")
            
            guard PQgetisnull(result.pointer, Int32(index), Int32(field.index)) == 0 else {
                return nil
            }
            
            let length = PQgetlength(result.pointer, Int32(index), Int32(field.index))
            let bytes = PQgetvalue(result.pointer, Int32(index), Int32(field.index))!
            
            let valueData = Data(bytes: bytes, count: Int(length))
            
            return PGRawValue(data: valueData, format: field.format)
        }
        
        /// Accesses the raw value of the field at `fieldIndex` in this tuple, or `nil` 
        /// if the field is `NULL`.
        /// 
        /// The returned `PGRawValue` will be binary if the field's `format` is 
        /// `binary`, or textual if its `format` is textual. This is usually determined 
        /// by the `resultFormat` parameter on the various `execute(…)` methods, 
        /// which defaults to `textual`.
        /// 
        /// This subscript returns a `PGRawValue`, which will require additional 
        /// processing to form a usable value. It's usually better to use the 
        /// `value(at:as:)` method, which immediately constructs a 
        /// `PGValue`-conforming type from the value.
        /// 
        /// - Precondition: `fieldIndex` is the index of a valid `Field` in the result.
        /// 
        /// - Recommended: `PGResult.Tuple.value(at:as:)`
        /// - RecommendedOver: `PQgetvalue`, `PQgetisnull`, `PQgetlength`
        public subscript(fieldIndex: Int) -> PGRawValue? {
            let field = result.fields[fieldIndex]
            return self[field]
        }
        
        /// Accesses the raw value of the field with `fieldName` in this tuple. 
        /// The value is `.some(nil)` if the field is `NULL`, or `nil` if no field for 
        /// `fieldName` exists.
        /// 
        /// The returned `PGRawValue` will be binary if the field's `format` is 
        /// `binary`, or textual if its `format` is textual. This is usually determined 
        /// by the `resultFormat` parameter on the various `execute(…)` methods, 
        /// which defaults to `textual`.
        /// 
        /// This subscript returns a `PGRawValue`, which will require additional 
        /// processing to form a usable value. It's usually better to use the 
        /// `value(at:as:)` method, which immediately constructs a 
        /// `PGValue`-conforming type from the value.
        /// 
        /// - Recommended: `PGResult.Tuple.value(at:as:)`
        /// - RecommendedOver: `PQgetvalue`, `PQgetisnull`, `PQgetlength`
        public subscript(fieldName: String) -> PGRawValue?? {
            guard let fieldIndex = result.fields.index(of: fieldName) else {
                return nil
            }
            return self[fieldIndex]
        }
        
        // WORKAROUND: Swift does not support generic subscripts 
        // 
        /// Accesses the value of `field` in this tuple, converting it to `valueType`,  
        /// or `nil` if the field is `NULL`.
        /// 
        /// - Parameter field: The field to access.
        /// - Parameter valueType: The type to convert the field's value into.
        /// - Throws: If the conversion to `valueType` fails.
        /// - Precondition: `field` is a `Field` from the same `PGResult` used to 
        ///                   access the `Tuple`.
        /// 
        /// - RecommendedOver: `PGResult.Tuple.subscript(_:)`
        public func value<Value: PGValue>(in field: Field, as valueType: Value.Type) throws -> Value? {
            let rawValue = self[field]
            return try rawValue.map(valueType.init(rawPGValue:))
        }
        
        // WORKAROUND: Swift does not support generic subscripts 
        // 
        /// Accesses the value of the field at `fieldIndex` in this tuple, converting 
        /// it to `valueType`, or `nil` if the field is `NULL`.
        /// 
        /// - Parameter fieldIndex: The index of the field to access.
        /// - Parameter valueType: The type to convert the field's value into.
        /// - Throws: If the conversion to `valueType` fails.
        /// - Precondition: `fieldIndex` is the index of a valid `Field` in the result.
        /// 
        /// - RecommendedOver: `PGResult.Tuple.subscript(_:)`
        public func value<Value: PGValue>(at fieldIndex: Int, as valueType: Value.Type) throws -> Value? {
            let field = result.fields[fieldIndex]
            return try self.value(in: field, as: valueType)
        }
        
        // WORKAROUND: Swift does not support generic subscripts 
        // 
        /// Accesses the value of the field with `fieldName` in this tuple, converting 
        /// it to `valueType`. The value is `.some(nil)` if the field is `NULL`, or 
        /// `nil` if no field for `fieldName` exists.
        /// 
        /// - Parameter fieldName: The name of the field to access.
        /// - Parameter valueType: The type to convert the field's value into.
        /// - Throws: If the conversion to `valueType` fails.
        /// - Precondition: `fieldIndex` is the index of a valid `Field` in the result.
        /// 
        /// - RecommendedOver: `PGResult.Tuple.subscript(_:)`
        public func value<Value: PGValue>(for fieldName: String, as valueType: Value.Type) throws -> Value?? {
            guard let fieldIndex = result.fields.index(of: fieldName) else {
                return nil
            }
            return try self.value(at: fieldIndex, as: valueType)
        }
    }
    
    /// Represents the set of tuples containing the data returned in a result.
    /// (You might think of the tuples as the "rows" of data returned by the result, 
    /// though technically they are not rows since they may not exactly match 
    /// rows in a table.)
    /// 
    /// A `TupleView` for a `PGResult` can be accessed through its `tuples` 
    /// property. It is an `Int`-indexed `RandomAccessCollection` whose elements 
    /// are all `Tuple` instances describing individual tuples returned by the result.
    /// 
    /// As a `RandomAccessCollection`, you can access the number of tuples 
    /// through the `count` property and obtain a particular tuple by 
    /// subscripting the `TupleView`. You can also loop over it with `for` or use 
    /// higher-order operations like `map`.
    /// 
    /// - Warning: The `TupleView` struct's properties and subscripts rely  
    ///              on the `PGResult` the instance is derived from to access the 
    ///              information. Do not use a `TupleView` from a `PGResult` which 
    ///              you have already `clear()`ed.
    public struct TupleView: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PGResult
        
        /// The index after the index of the last tuple.
        /// 
        /// - RecommendedOver: `PQntuples`
        public var endIndex: Int {
            return Int(PQntuples(result.pointer))
        }
        
        /// Retrieves the `i`th tuple in the result.
        /// 
        /// - Precondition: There are at least `i + 1` tuples in the result.
        public subscript(i: Int) -> Tuple {
            precondition(i < endIndex, "Index out of bounds")
            return Tuple(result: result, index: i)
        }
        
        public typealias Indices = DefaultRandomAccessIndices<TupleView>
    }
}
