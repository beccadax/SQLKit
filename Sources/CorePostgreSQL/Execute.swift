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
    public func execute(_ sql: String, withRaw parameterValues: [PGRawValue?], ofTypes parameterTypes: [PGType?] = [], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        var typeOids = oids(of: parameterTypes)
        
        // We need to pad this to the same length as the other arrays.
        let shortfall = parameterValues.count - parameterTypes.count 
        if shortfall > 0 {
            typeOids += repeatElement(PGType.automaticOid, count: shortfall)
        }
        
        let resultPointer = withDeconstructed(parameterValues) { valueBuffers, lengths, formats in
            PQexecParams(pointer, sql, Int32(valueBuffers.count), typeOids, valueBuffers, lengths, formats, resultFormat.rawValue)!
        }
        
        return try PGResult(pointer: resultPointer)
    }
    
    public func execute(_ sql: String, with parameterValues: [PGValue?], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        let (rawParameters, types) = rawValues(of: parameterValues)
        return try execute(sql, withRaw: rawParameters, ofTypes: types, resultingIn: resultFormat)
    }
    
    /// - RecommendedOver: `PQprepare`
    public func prepare(_ sql: String, withRawTypes types: [PGType?] = [], name: String? = nil) throws -> PGPreparedStatement {
        let name = name ?? ProcessInfo.processInfo.globallyUniqueString
        let typeOids = oids(of: types)
        
        let resultPointer = PQprepare(pointer, name, sql, Int32(typeOids.count), typeOids)!
        _ = try PGResult(pointer: resultPointer)
        
        return PGPreparedStatement(connection: self, name: name, deallocatingOnDeinit: true)
    }
}

extension PGPreparedStatement {
    /// - RecommendedOver: `PQexecPrepared`
    public func execute(withRaw parameterValues: [PGRawValue?], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        guard let name = self.name else {
            preconditionFailure("Called execute(with:) on deallocated prepared statement")
        }
        
        let resultPointer = withDeconstructed(parameterValues) { valueBuffers, lengths, formats in
            PQexecPrepared(self.connection.pointer, name, Int32(valueBuffers.count), valueBuffers, lengths, formats, resultFormat.rawValue)!
        }
        
        return try PGResult(pointer: resultPointer)
    }
    
    
    public func execute(with parameterValues: [PGValue?], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        let (rawParameters, _) = rawValues(of: parameterValues)
        return try execute(withRaw: rawParameters, resultingIn: resultFormat)
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
