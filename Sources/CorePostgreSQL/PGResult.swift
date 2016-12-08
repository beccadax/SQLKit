//
//  PGResult.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

/// Represents the results returned by exectuting a statement.
/// 
/// A `PGResult` object has several important aspects:
/// 
/// * The `status` property tells you whether the query encountered warnings and, 
///    if so, lets you access their details.
/// * The `fields` property describes the fields returned by the query, including 
///    the number of fields and the name, type, and other details of each one.
/// * The `tuples` property lets you count the number of tuples returned by the 
///    query and access each one.
/// 
/// The `fields` and `tuples` properties both conform to `RandomAccessCollection`, 
/// so you can use them in `for` loops, with higher-order functions like `map` and 
/// `filter`, or subscript them with integers.
/// 
/// When you're done with the result, the `clear()` method will wipe its data and  
/// free up related resources. If you don't call it yourself, `PGResult` will call 
/// it for you just before it's deinitialized.
public final class PGResult {
    /// The raw pointer to the underlying `PGresult` struct in `libpq`. Can be used  
    /// to bypass `CorePostgreSQL` and use `libpq` directly.
    public private(set) var pointer: OpaquePointer?
    
    /// Constructs a `PGConn` object from a low-level `libpq` `PGconn` pointer.
    ///
    /// - Parameter pointer: A pointer returned by a `PQexec`-related function.
    ///
    /// - Throws: A `PGResult.Error` if the status is not one of `PGRES_COMMAND_OK`, `PGRES_TUPLES_OK`, `PGRES_SINGLE_TUPLE`, or `PGRES_NONFATAL_ERROR`.
    /// - SeeAlso: `PGConn.execute(_:with:resultingIn:)`
    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer
        
        let status = self.status 
        guard status.isSuccessful else {
            throw PGError.executionFailed(status)
        }
    }
    
    /// Deallocates the data associated with the query result.
    /// 
    /// - Warning: After calling this method, do not use any other properties or 
    ///              methods of the object, nor of any `FieldView`, `Field`, 
    ///              `TupleView`, or `Tuple` derived from it.
    /// 
    /// - RecommendedOver: `PQclear`
    public func clear() {
        guard let ptr = pointer else {
            return
        }
        PQclear(ptr)
        pointer = nil
    }
    
    deinit {
        clear()
    }
}
