//
//  PreparedStatement.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation

extension PostgreSQL {
    public final class PreparedStatement {
        public let connection: Connection
        public private(set) var name: String?
        public let deallocating: Bool
        
        public init(connection: Connection, name: String, deallocating: Bool = false) {
            self.connection = connection
            self.name = name
            self.deallocating = deallocating
        }
        
        public func deallocate() throws {
            guard let name = name else {
                return
            }
            
            _ = try connection.execute("DEALLOCATE $1", with: [.init(value: name)])
            self.name = nil
        }
        
        deinit {
            if deallocating { _ = try? deallocate() }
        }
    }
}
