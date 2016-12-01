//
//  Result.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

public final class PGResult {
    public private(set) var pointer: OpaquePointer?
    
    /// - Throws: A `PGResult.Error` if the status is not one of `PGRES_COMMAND_OK`, `PGRES_TUPLES_OK`, `PGRES_SINGLE_TUPLE`, or `PGRES_NONFATAL_ERROR`.
    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer
        
        let error = self.error 
        switch error.status {
        case PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_SINGLE_TUPLE, PGRES_NONFATAL_ERROR:
            break
            
        default:
            throw error
        }
    }
    
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
