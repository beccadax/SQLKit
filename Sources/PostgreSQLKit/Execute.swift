//
//  Execute.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PGConn {
    /// - RecommendedOver: `PQexec`
    public func execute(_ sql: String) throws -> PGResult {
        let resultPointer = PQexec(pointer, sql)!
        return try PGResult(pointer: resultPointer)
    }
    
    /// - RecommendedOver: `PQexecParams`
    public func execute(_ sql: String, with parameterValues: [PGRawValue?], ofTypes parameterTypes: [Oid?] = [], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        let resultPointer = withDeconstructed(parameterValues) { valueBuffers, lengths, formats in
            PQexecParams(pointer, sql, Int32(valueBuffers.count), parameterTypes.map { $0 ?? 0 }, valueBuffers, lengths, formats, resultFormat.rawValue)!
        }
        
        return try PGResult(pointer: resultPointer)
    }
    
    /// - RecommendedOver: `PQprepare`
    public func prepare(_ sql: String, withTypes types: [Oid?] = [], name: String? = nil) throws -> PGPreparedStatement {
        let name = name ?? ProcessInfo.processInfo.globallyUniqueString
        
        let resultPointer = PQprepare(pointer, name, sql, Int32(types.count), types.map { $0 ?? 0 })!
        _ = try PGResult(pointer: resultPointer)
        
        return PGPreparedStatement(connection: self, name: name, deallocating: true)
    }
}

extension PGPreparedStatement {
    /// - RecommendedOver: `PQexecPrepared`
    public func execute(with parameterValues: [PGRawValue?], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        guard let name = self.name else {
            preconditionFailure("Called execute(with:) on deallocated prepared statement")
        }
        
        let resultPointer = withDeconstructed(parameterValues) { valueBuffers, lengths, formats in
            PQexecPrepared(self.connection.pointer, name, Int32(valueBuffers.count), valueBuffers, lengths, formats, resultFormat.rawValue)!
        }
        
        return try PGResult(pointer: resultPointer)
    }
}

fileprivate func withDeconstructed<R>(_ parameterValues: [PGRawValue?], do body: (_ buffers: [UnsafePointer<Int8>?], _ lengths: [Int32], _ formats: [Int32]) throws -> R) rethrows -> R {
    var datas: [Data?] = []
    var lengths: [Int32] = []
    var formats: [Int32] = []
    
    for value in parameterValues {
        let data = value?.data
        let length = Int32(data?.count ?? 0)
        let format = value?.format ?? .textual
        
        datas.append(data)
        lengths.append(length)
        formats.append(format.rawValue)
    }
    
    return try withUnsafePointers(to: datas) {
        try body($0, lengths, formats)
    }
}
