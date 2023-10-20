//
//  Execute.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/28/16.
//
//

import Foundation
import Clibpq

extension PGConn {
    /// Execute one or more SQL statements, returning the result of the last 
    /// statement. 
    /// 
    /// - Parameter sql: The SQL to run.
    /// - Returns: The result of the last statement in the SQL to run.
    /// - Throws: `SQLError.executionFailed` if any of the statements failed.
    /// 
    /// - Note: If you need to substitute any values into the statement, use 
    ///          `execute(_:with:resultingIn:)` instead. That method will pass the 
    ///          parameters out-of-band, avoiding the risk of a SQL injection attack.
    /// 
    /// - RecommendedOver: `PQexec`
    public func execute(_ sql: String) throws -> PGResult {
        let resultPointer = PQexec(pointer, sql)!
        return try PGResult(pointer: resultPointer)
    }
    
    /// Executes a SQL statement, binding the indicated parameter raw values to any 
    /// placeholders with the indicated types.
    /// 
    /// - Parameter sql: The SQL to run, with placeholders of the form `$1`, `$2`, 
    ///               etc. marking the parameters.
    /// - Parameter parameterValues: The parameters expressed as `PGRawValue`s. 
    ///               `nil` values will be treated as `NULL`.
    /// - Parameter parameterTypes: The types of the parameters. `nil` or 
    ///               unspecified parameters will have a type automatically chosen.
    /// - Parameter resultFormat: The format the columns in the result should be 
    ///               returned in. This should be `textual` unless all of the types 
    ///               of the columns conform to `SQLBinaryValue`.
    /// - Returns: The result of the statement.
    /// - Throws: `SQLError.executionFailed` if the statement failed.
    /// 
    /// - Note: This call requires you to manually create `PGRawValue`s for the 
    ///          parameters. It will usually be more convenient to use 
    ///          `execute(_:with:resultingIn:)`, which automatically converts its 
    ///          `PGValue` parameters into `PGRawValue`s.
    /// 
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
    
    /// Executes a SQL statement, binding the indicated parameter values to any 
    /// placeholders.
    /// 
    /// - Parameter sql: The SQL to run, with placeholders of the form `$1`, `$2`, 
    ///               etc. marking the parameters.
    /// - Parameter parameterValues: The parameters, which must be `PGValue`s. 
    ///               `nil` values will be treated as `NULL`.
    /// - Parameter resultFormat: The format the columns in the result should be 
    ///               returned in. This should be `textual` unless all of the types 
    ///               of the columns conform to `SQLBinaryValue`.
    /// - Returns: The result of the statement.
    /// - Throws: `SQLError.executionFailed` if the statement failed.
    /// 
    /// - RecommendedOver: `PQexecParams`, `execute(_:withRaw:ofTypes:resultingIn:)`
    public func execute(_ sql: String, with parameterValues: [PGValue?], resultingIn resultFormat: PGRawValue.Format = .textual) throws -> PGResult {
        let (rawParameters, types) = rawValues(of: parameterValues)
        return try execute(sql, withRaw: rawParameters, ofTypes: types, resultingIn: resultFormat)
    }
    
    /// Prepares a SQL statement for later execution.
    /// 
    /// - Parameter sql: The SQL to run, with placeholders of the form `$1`, `$2`, 
    ///               etc. marking the parameters.
    /// - Parameter types: The types of the parameters. `nil` or unspecified  
    ///               parameters will have a type automatically chosen.
    /// - Parameter name: The name of the prepared statement. If `nil`, a name 
    ///               will be generated automatically.
    /// - Returns: A `PGPreparedStatement` instance which can be used to execute 
    ///             the query.
    /// - Throws: `SQLError.executionFailed` if preparing the statement failed.
    /// 
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
    /// Executes a prepared SQL statement, binding the indicated parameter raw  
    /// values to any placeholders.
    /// 
    /// - Parameter parameterValues: The parameters expressed as `PGRawValue`s. 
    ///               `nil` values will be treated as `NULL`.
    /// - Parameter resultFormat: The format the columns in the result should be 
    ///               returned in. This should be `textual` unless all of the types 
    ///               of the columns conform to `SQLBinaryValue`.
    /// - Returns: The result of the statement.
    /// - Throws: `SQLError.executionFailed` if the statement failed.
    /// 
    /// - Note: This call requires you to manually create `PGRawValue`s for the 
    ///          parameters. It will usually be more convenient to use 
    ///          `execute(with:resultingIn:)`, which automatically converts its 
    ///          `PGValue` parameters into `PGRawValue`s.
    /// 
    /// - Precondition: The prepared statement has not been deallocated.
    /// 
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
    
    /// Executes a prepared SQL statement, binding the indicated parameter   
    /// values to any placeholders.
    /// 
    /// - Parameter parameterValues: The parameters, which must be `PGValue`s. 
    ///               `nil` values will be treated as `NULL`.
    /// - Parameter resultFormat: The format the columns in the result should be 
    ///               returned in. This should be `textual` unless all of the types 
    ///               of the columns conform to `SQLBinaryValue`.
    /// - Returns: The result of the statement.
    /// - Throws: `SQLError.executionFailed` if the statement failed.
    /// 
    /// - Precondition: The prepared statement has not been deallocated.
    /// 
    /// - RecommendedOver: `PQexecPrepared`
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
