//
//  PostgreSQLValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation
import SQLKit
import CorePostgreSQL

extension SQLValue {
    static func checkPGValueCompatibility() throws {
        switch Self.self {
        case is PGValue.Type:
            return
            
        case is SQLStringConvertible.Type:
            return
            
        default:
            throw SQLValueError.typeUnsupportedByClient(valueType: self, client: PostgreSQL.self)
        }
    }
    
    init(rawPGValueForSQLKit rawValue: PGRawValue) throws {
        switch Self.self {
        case let selfType as PGValue.Type:
            self = try selfType.init(rawPGValue: rawValue) as! Self
            
        case let convertibleType as SQLStringConvertible.Type:
            let string = try String(rawPGValue: rawValue)
            self = try convertibleType.init(sqlLiteral: string) as! Self
            
        default:
            throw SQLValueError.typeUnsupportedByClient(valueType: Self.self, client: PostgreSQL.self)
        }
    }
    
    func toPGValueForSQLKit() throws -> PGValue {
        switch self {
        case let pgValue as PGValue:
            return pgValue
        
        case let convertible as SQLStringConvertible:
            return convertible.sqlLiteral
            
        default:
            throw SQLValueError.typeUnsupportedByClient(valueType: Self.self, client: PostgreSQL.self)
        }
    }
}
