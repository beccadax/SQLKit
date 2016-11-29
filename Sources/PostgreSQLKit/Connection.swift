//
//  Connection.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PostgreSQL {
    public final class Connection {
        public struct Error: LocalizedError {
            public fileprivate(set) var errorDescription: String
        }
        
        public private(set) var pointer: OpaquePointer?
        
        /// - Throws: If the status is `CONNECTION_BAD`.
        public init(pointer: OpaquePointer) throws {
            self.pointer = pointer
            
            if let error = connectionError {
                throw error
            }
        }
        
        /// - RecommendedOver: `PQconnectdb`
        public convenience init(connectingToURL url: URL) throws {
            try self.init(pointer: PQconnectdb(url.absoluteString)!)
        }
        
        /// - RecommendedOver: `PQstatus`, `PQerrorMessage`
        public var connectionError: Error? {
            let status = PQstatus(pointer)
            guard status != CONNECTION_BAD else {
                let message = String(validatingUTF8: PQerrorMessage(pointer))!
                return Error(errorDescription: message)
            }
            
            return nil
        }
        
        /// - RecommendedOver: `PQfinish`
        public func finish() {
            guard let ptr = pointer else {
                return
            }
            
            PQfinish(ptr)
            pointer = nil
        }
        
        deinit {
            finish()
        }
    }
}
