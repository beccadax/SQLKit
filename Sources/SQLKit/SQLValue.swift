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
/// `SQLValue` does not have any requirements, and it cannot guarantee that the 
/// specific SQL client you're using will be able to handle the `SQLValue` you 
/// provide. Rather, it serves to weed out types which are not supported by *any* 
/// SQL client. 
/// 
/// SQL clients are required to support the following types:
/// 
/// * `String`
/// * `Data`
/// * `Bool`
/// * `Int`
/// * `Double`
/// * `Date`
/// * Types conforming to `SQLStringConvertible` (treated as `String`s)
/// 
/// When a SQL client encounters a type it doesn't support, it should throw 
/// `SQLValueError.typeUnsupportedByClient`. They should also conform any 
/// additional supported types to `SQLValue`.
/// 
/// - SeeAlso: `SQLStringConvertible`
public protocol SQLValue {}

extension String: SQLValue {}
extension Data: SQLValue {}
extension Bool: SQLValue {}
extension Int: SQLValue {}
extension Double: SQLValue {}
extension Date: SQLValue {}

/// Conforming types should be represented to SQL clients as the string returned by 
/// the `sqlLiteral` property.
/// 
/// Unlike the parent `SQLValue` protocol, a `SQLStringConvertible` type does not 
/// correspond to any type the SQL server is expected to support; rather, it should 
/// be stored in something like a VARCHAR or TEXT column. For instance, `URL` 
/// is a `SQLStringConvertible` type.
/// 
/// A `LosslessStringConvertible` type which is conformed to `SQLStringConvertible` 
/// will automatically have that conformance used by `SQLStringConvertible`.
public protocol SQLStringConvertible: SQLValue {
    /// Creates a value of this type from the SQL literal string. The string has no 
    /// quotes or escaping.
    /// 
    /// - Throws: If the value cannot be converted. Use 
    ///             `SQLValueError.stringNotConvertible` if there is no more specific 
    ///             information available.
    init(sqlLiteral string: String) throws
    
    /// A string which a typical SQL engine would be happy to accept in order to set 
    /// or match this value. The string should have no quotes or escaping.
    var sqlLiteral: String { get }
}

extension SQLStringConvertible where Self: LosslessStringConvertible {
    public init(sqlLiteral string: String) throws {
        guard let value = Self(string) else {
            throw SQLValueError.stringNotConvertible(sqlLiteral: string, type: Self.self)
        }
        self = value
    }
    
    public var sqlLiteral: String {
        return String(description)
    }
}

extension URL: SQLStringConvertible {
    /// Converts from a URL represented as a string.
    public init(sqlLiteral string: String) throws {
        guard let value = URL(string: string) else {
            throw SQLValueError.stringNotConvertible(sqlLiteral: string, type: type(of: self))
        }
        self = value
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
