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
    public struct Field {
        let result: PGResult
        public let index: Int
        
        /// - PreferredOver: `PQftype`
        public var type: Oid? {
            return PQftype(result.pointer, Int32(index))
        }
        
        /// - PreferredOver: `PQfmod`
        public var typeModifier: Int? {
            let mod = PQfmod(result.pointer, Int32(index))
            if mod == -1 {
                return nil
            }
            return Int(mod)
        }
        
        /// - PreferredOver: `PQfname`
        public var name: String {
            guard let cString = PQfname(result.pointer, Int32(index)) else {
                preconditionFailure("Index out of range")
            }
            return String(cString: cString)
        }
        
        /// - PreferredOver: `PQftable`
        public var table: Oid? {
            let tableID = PQftable(result.pointer, Int32(index))
            
            if tableID == InvalidOid {
                return nil
            }
            return tableID
        }
        
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
        
        public var format: PGRawValue.Format {
            let raw = PQfformat(result.pointer, Int32(index))
            return PGRawValue.Format(rawValue: raw)!
        }
    }
    
    public struct FieldView: _IntIndexedCollection, RandomAccessCollection {
        fileprivate let result: PGResult
        
        /// - PreferredOver: `PQnfields`
        public var endIndex: Int {
            return Int(PQnfields(result.pointer))
        }
        
        public subscript(i: Int) -> Field {
            precondition(i < endIndex, "Index out of bounds")
            return Field(result: result, index: i)
        }
        
        /// - PreferredOver: `PQfnumber`
        public func index(of name: String) -> Int? {
            let i = PQfnumber(result.pointer, name)
            if i == -1 { return nil }
            return Int(i)
        }
        
        public typealias Indices = DefaultRandomAccessIndices<FieldView>
    }
    
    public var fields: FieldView {
        return FieldView(result: self)
    }
}
