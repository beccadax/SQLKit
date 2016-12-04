//
//  PostgreSQLKitError.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation
import CorePostgreSQL

enum PostgreSQLKitError: Error {
    case invalidDate(PGTimestamp)
}

extension PostgreSQLKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidDate(let timestamp):
            return NSLocalizedString("Cannot convert \(timestamp) to an NSDate.", comment: "")
        }
    }
}
