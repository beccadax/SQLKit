//
//  ResultTuple.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PostgreSQL.Result {
    public var tuples: TupleView {
        return TupleView(result: self)
    }
    
    public struct Tuple: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PostgreSQL.Result
        public let index: Int
        
        public var endIndex: Int {
            return result.fields.endIndex
        }
        
        /// - PreferredOver: `PQgetvalue`, `PQgetisnull`, `PQgetlength`
        public subscript(fieldIndex: Int) -> String? {
            guard PQgetisnull(result.pointer, Int32(index), Int32(fieldIndex)) == 0 else {
                return nil
            }
            
            let length = PQgetlength(result.pointer, Int32(index), Int32(fieldIndex))
            let bytes = PQgetvalue(result.pointer, Int32(index), Int32(fieldIndex))!
            
            let valueData = Data(bytes: bytes, count: Int(length))
            
            return String(data: valueData, encoding: .utf8)
        }
        
        public subscript(field: Field) -> String? {
            precondition(field.result === result, "Used a Field from one Result to access a Tuple from another Result")
            return self[field.index]
        }
        
        public subscript(fieldName: String) -> String?? {
            guard let fieldIndex = result.fields.index(of: fieldName) else {
                return nil
            }
            return self[fieldIndex]
        }
    }

    public struct TupleView: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PostgreSQL.Result
        
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
