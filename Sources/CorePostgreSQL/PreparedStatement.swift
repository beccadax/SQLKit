//
//  PreparedStatement.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation

public final class PGPreparedStatement {
    public let connection: PGConn
    public private(set) var name: String?
    public let deallocateOnDeinit: Bool
    
    public init(connection: PGConn, name: String, deallocatingOnDeinit: Bool = false) {
        self.connection = connection
        self.name = name
        self.deallocateOnDeinit = deallocatingOnDeinit
    }
    
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
