//
//  PGPreparedStatement.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation

/// A statement which PostgreSQL has already parsed and gotten ready to execute.
/// 
/// Prepared statements can help you use the database more efficiently if you 
/// execute the same statement repeatedly with different values in its placeholders. 
/// However, they shouldn't be used for one-off statements, because they add 
/// overhead and tie up additional resources.
/// 
/// There is no equivalent to this type in `libpq`. `PGPreparedStatement` abstracts 
/// over the built-in support by wrapping up the statement name and connection 
/// together in a single type which also automatically manages the prepared 
/// statement's lifetime.
/// 
/// - Warning: This type is *especially* untested.
public final class PGPreparedStatement {
    /// The connection which this statement belongs to.
    public let connection: PGConn
    /// The name of this statement, or `nil` if the statement has been deallocated.
    public private(set) var name: String?
    /// If `true`, the `PGPreparedStatement` will execute a `DEALLOCATE` statement  
    /// when it's deinitialized.
    public let deallocateOnDeinit: Bool
    
    /// Creates a new `PGPreparedStatement` object representing a statement which   
    /// has already been prepared.
    /// 
    /// - Parameter connection: The connection which this statement belongs to.
    /// - Parameter name: The name of this statement.
    /// - Parameter deallocatingOnDeinit: If `true`, the `PGPreparedStatement`   
    ///               will execute a `DEALLOCATE` statement when it's deinitialized.
    /// 
    /// - SeeAlso: `PGConn.prepare(_:withTypes:name:)`
    public init(connection: PGConn, name: String, deallocatingOnDeinit: Bool = false) {
        self.connection = connection
        self.name = name
        self.deallocateOnDeinit = deallocatingOnDeinit
    }
    
    /// Removes the prepared statement from the server. After calling this method,   
    /// the prepared statement can no longer be executed.
    /// 
    /// If `deallocateOnDeinit` is `true`, this method will be called automatically 
    /// when the object is deinitialized.
    public func deallocate() throws {
        guard let name = name else {
            return
        }
        
        _ = try connection.execute("DEALLOCATE $1", with: [name])
        self.name = nil
    }
    
    deinit {
        if deallocateOnDeinit { _ = try? deallocate() }
    }
}
