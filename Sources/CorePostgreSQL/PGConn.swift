//
//  PGConn.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

/// Represents a connection to a PostgreSQL database.
/// 
/// `PGConn` is your first stop when working with `CorePostgreSQL`; you can't 
/// really do much without it. Once you've connected to a database, you can 
/// execute queries using the `PGConn` instance.
/// 
/// When you're done with the connection, the `finish()` method will disconnect it 
/// and free up related resources. If you don't call it yourself, `PGConn` will call 
/// it for you just before it's deinitialized.
public final class PGConn {
    /// The raw pointer to the underlying `PGconn` struct in `libpq`. Can be used to 
    /// perform extremely low-level operations.
    public private(set) var pointer: OpaquePointer?
    
    /// Constructs a `PGConn` object from a low-level `libpq` `PGconn` pointer.
    /// 
    /// As a side effect, this initializer sets certain configuration variables on the 
    /// connection to values necessary to make `CorePostgreSQL` function. Do not 
    /// override these changes.
    /// 
    /// - Parameter pointer: A pointer from `libpq`'s `connectdb(_:)` or similar 
    ///               function.
    /// 
    /// - Throws: `PGError.connectionFailed` if the status is `CONNECTION_BAD`.
    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer
        if let error = connectionError {
            throw error
        }
        
        clientEncoding = .utf8
        dateStyle = DateStyle(format: .iso, order: .ymd)
        intervalStyle = .iso8601
    }
    
    /// Connects to a PostgreSQL database using a `postgres:` or `postgresql:` 
    /// URL.
    ///
    /// - Parameter url: A URL in the [format accepted by `libpq`](https://www.postgresql.org/docs/9.4/static/libpq-connect.html#AEN41287). 
    ///
    /// - Throws: `PGError.connectionFailed` if  the connection fails.
    /// 
    /// - RecommendedOver: `PQconnectdb`
    public convenience init(connectingToURL url: URL) throws {
        try self.init(pointer: PQconnectdb(url.absoluteString)!)
    }
    
    /// - RecommendedOver: `PQstatus`, `PQerrorMessage`
    internal var connectionError: Error? {
        let status = PQstatus(pointer)
        guard status != CONNECTION_BAD else {
            let message = String(validatingUTF8: PQerrorMessage(pointer))!
            return PGError.connectionFailed(message: message)
        }
        
        return nil
    }
    
    /// Closes the connection and cleans up the underlying data structures. Once 
    /// this method has been run, the connection cannot be used again.
    /// 
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
