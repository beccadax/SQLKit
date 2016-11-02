//
//  SQLValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/29/16.
//
//

import Foundation

/// Conforming types can be taken as parameters or returned as values by at least 
/// one SQL client.
/// 
/// A `SQLValue` can be converted to and from a `sqlLiteral` representation. This is 
/// a string without quoting or escaping which could be used to set the column 
/// in your database.
/// 
/// Individual SQL clients may ignore the `sqlLiteral` representation and substitute 
/// their own.
/// 
/// - SeeAlso: `SQLStringConvertible`
public protocol SQLValue {
    /// Creates a value of this type from the SQL literal string. The string has no 
    /// quotes or escaping.
    init?(sqlLiteral string: String)
    /// A string which a typical SQL engine would be happy to accept in order to set 
    /// or match this value. The string should have no quotes or escaping.
    var sqlLiteral: String { get }
}

/// Conforming types should be represented to SQL clients as the string returned by 
/// the `sqlLiteral` property.
/// 
/// Unlike the parent `SQLValue` protocol, a `SQLStringConvertible` type does not 
/// correspond to any type the SQL server is expected to support; rather, it should 
/// be stored in something like a VARCHAR or TEXT column. For instance, `URL` 
/// is a `SQLStringConvertible` type.
public protocol SQLStringConvertible: SQLValue {}

extension SQLValue where Self: LosslessStringConvertible {
    public init?(sqlLiteral string: String) {
        self.init(string)
    }
    
    public var sqlLiteral: String {
        return String(description)
    }
}

extension String: SQLValue {}
extension Int: SQLValue {}

extension Date: SQLValue {
    private static let postgresFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        return formatter
    }()
    
    /// Converts from a date represented in a typical ISO-8601-style SQL format.
    /// 
    /// By default, `Date`s are represented in UTC in the format 
    /// `yyyy-MM-dd HH:mm:ss.SSSSSS`.
    public init?(sqlLiteral string: String) {
        guard let d = Date.postgresFormatter.date(from: string) else {
            return nil
        }
        self = d
    }
    
    /// Converts to a date represented in a typical ISO-8601-style SQL format.
    /// 
    /// By default, `Date`s are represented in UTC in the format 
    /// `yyyy-MM-dd HH:mm:ss.SSSSSS`.
    public var sqlLiteral: String {
        return Date.postgresFormatter.string(from: self)
    }
}

extension Data: SQLValue {
    /// Converts from a blob literal represented in hexadecimal format.
    public init?(sqlLiteral string: String) {
        self.init(hexEncoded: string)
    }
    
    /// Converts to a blob literal represented in hexadecimal format.
    public var sqlLiteral: String {
        return hexEncodedString()
    }
}

extension URL: SQLStringConvertible {
    /// Converts from a URL represented as a string.
    public init?(sqlLiteral string: String) {
        self.init(string: string)
    }
    
    /// Converts to a URL represented as a string.
    /// 
    /// - Note: There is no distinction between the relative and absolute parts of 
    ///           the URL, so they will be merged when the URL returns through this 
    ///           protocol.
    public var sqlLiteral: String {
        return absoluteString
    }
}
