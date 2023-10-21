//
//  PostgreSQLValueCompatibility.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/4/16.
//
//

import Foundation
import CorePostgreSQL

extension Date: PGValueConvertible {
    init(pgValue value: PGTimestamp) throws {
        guard let date = Date(value) else {
            throw PostgreSQLKitError.invalidDate(value)
        }
        self = date
    }
    
    var pgValue: PGTimestamp {
        return PGTimestamp(self)
    }
}

extension Decimal: SQLValue {}
extension PGTimestamp: SQLValue {}
extension PGDate: SQLValue {}
extension PGTime: SQLValue {}
extension PGInterval: SQLValue {}
