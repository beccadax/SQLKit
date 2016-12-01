//
//  Execute.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PostgreSQL.Connection {
    /// - RecommendedOver: `PQexec`
    public func execute(_ sql: String) throws -> PostgreSQL.Result {
        let resultPointer = PQexec(pointer, sql)!
        return try PostgreSQL.Result(pointer: resultPointer)
    }
    
    /// - RecommendedOver: `PQexecParams`
    public func execute(_ sql: String, with parameterValues: [PostgreSQL.RawValue?], ofTypes parameterTypes: [Oid?] = [], resultingIn resultFormat: PostgreSQL.RawValue.Format = .textual) throws -> PostgreSQL.Result {
        var parameterDatas: [Data?] = []
        var parameterLengths: [Int32] = []
        var parameterFormats: [Int32] = []
        
        for value in parameterValues {
            let deconstructed = value?.deconstruct() ?? (data: nil, length: 0, format: 0)
            
            parameterDatas.append(deconstructed.data)
            parameterLengths.append(deconstructed.length)
            parameterFormats.append(deconstructed.format)
        }
        
        let resultPointer = withUnsafePointers(to: parameterDatas) {
            PQexecParams(pointer, sql, Int32($0.count), parameterTypes.map { $0 ?? 0 }, $0, parameterLengths, parameterFormats, resultFormat.rawValue)!
        }
        
        return try PostgreSQL.Result(pointer: resultPointer)
    }
    
    /// - RecommendedOver: `PQprepare`
    public func prepare(_ sql: String, withTypes types: [Oid?] = [], name: String? = nil) throws -> PostgreSQL.PreparedStatement {
        let name = name ?? ProcessInfo.processInfo.globallyUniqueString
        
        let resultPointer = PQprepare(pointer, name, sql, Int32(types.count), types.map { $0 ?? 0 })!
        _ = try PostgreSQL.Result(pointer: resultPointer)
        
        return PostgreSQL.PreparedStatement(connection: self, name: name, deallocating: true)
    }
}

extension PostgreSQL.PreparedStatement {
    /// - RecommendedOver: `PQexecPrepared`
    public func execute(with parameterValues: [PostgreSQL.RawValue?], resultingIn resultFormat: PostgreSQL.RawValue.Format = .textual) throws -> PostgreSQL.Result {
        guard let name = name else {
            preconditionFailure("Called execute(with:) on deallocated prepared statement")
        }
        
        var parameterDatas: [Data?] = []
        var parameterLengths: [Int32] = []
        var parameterFormats: [Int32] = []
        
        for value in parameterValues {
            let deconstructed = value?.deconstruct() ?? (data: nil, length: 0, format: 0)
            
            parameterDatas.append(deconstructed.data)
            parameterLengths.append(deconstructed.length)
            parameterFormats.append(deconstructed.format)
        }
        
        let resultPointer = withUnsafePointers(to: parameterDatas) {
            PQexecPrepared(connection.pointer, name, Int32($0.count), $0, parameterLengths, parameterFormats, resultFormat.rawValue)!
        }
        
        return try PostgreSQL.Result(pointer: resultPointer)
    }
}


extension PostgreSQL.RawValue {
    fileprivate func deconstruct() -> (data: Data?, length: Int32, format: Int32) {
        var encodedData: Data
        
        switch self {
        case .textual(let string):
            encodedData = string.data(using: .utf8)!
            encodedData.append(0)
            
        case .binary(let data):
            encodedData = data
        }
        
        return (encodedData, Int32(encodedData.count), format.rawValue)
    }
}
