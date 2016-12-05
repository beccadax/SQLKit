//
//  PostgreSQLKitError.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation
import CorePostgreSQL

/// Errors specific to `PostgreSQLKit`.
/// 
/// Note that most errors you might find underlying `SQLError`s will *not* be 
/// `PostgreSQLKitError`s, but rather `PGError`s from the underlying 
/// `CorePostgreSQL` library. If you want to perform rich, detailed matching of 
/// errors, use that type to do so.
public enum PostgreSQLKitError: Error {
    /// The timestamp does not correspond to a valid date in the Gregorian 
    /// calendar, so it cannot be converted to a `Date`.
    case invalidDate(PGTimestamp)
}

extension PostgreSQLKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidDate(let timestamp):
            return NSLocalizedString("Cannot convert \(timestamp) to an NSDate.", comment: "")
        }
    }
}
