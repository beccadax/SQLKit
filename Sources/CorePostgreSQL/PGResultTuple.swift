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
    public var tuples: TupleView {
        return TupleView(result: self)
    }
    
    public struct Tuple: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PGResult
        public let index: Int
        
        public var endIndex: Int {
            return result.fields.endIndex
        }
        
        /// - PreferredOver: `PQgetvalue`, `PQgetisnull`, `PQgetlength`
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
        
        public subscript(fieldIndex: Int) -> PGRawValue? {
            let field = result.fields[fieldIndex]
            return self[field]
        }
        
        public subscript(fieldName: String) -> PGRawValue?? {
            guard let fieldIndex = result.fields.index(of: fieldName) else {
                return nil
            }
            return self[fieldIndex]
        }
        
        // WORKAROUND: Swift does not support generic subscripts 
        public func value<Value: PGValue>(in field: Field, as valueType: Value.Type) throws -> Value? {
            let rawValue = self[field]
            return try rawValue.map(valueType.init(rawPGValue:))
        }
        
        public func value<Value: PGValue>(at fieldIndex: Int, as valueType: Value.Type) throws -> Value? {
            let field = result.fields[fieldIndex]
            return try self.value(in: field, as: valueType)
        }
        
        public func value<Value: PGValue>(for fieldName: String, as valueType: Value.Type) throws -> Value?? {
            guard let fieldIndex = result.fields.index(of: fieldName) else {
                return nil
            }
            return try self.value(at: fieldIndex, as: valueType)
        }
    }

    public struct TupleView: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PGResult
        
        /// - PreferredOver: `PQntuples`
        public var endIndex: Int {
            return Int(PQntuples(result.pointer))
        }
        
        public subscript(i: Int) -> Tuple {
            precondition(i < endIndex, "Index out of bounds")
            return Tuple(result: result, index: i)
        }
        
        public typealias Indices = DefaultRandomAccessIndices<TupleView>
    }
}
