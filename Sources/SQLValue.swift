//
//  SQLValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/29/16.
//
//

import Foundation

public protocol SQLValue {
    init?(sqlLiteral string: String)
    var sqlLiteral: String { get }
}

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
    
    public init?(sqlLiteral string: String) {
        guard let d = Date.postgresFormatter.date(from: string) else {
            return nil
        }
        self = d
    }
    
    public var sqlLiteral: String {
        return Date.postgresFormatter.string(from: self)
    }
}

extension Data: SQLValue {
    public init?(sqlLiteral string: String) {
        self.init(hexEncoded: string)
    }
    
    public var sqlLiteral: String {
        return hexEncodedString()
    }
}

extension URL: SQLStringConvertible {
    public init?(sqlLiteral string: String) {
        self.init(string: string)
    }
    
    public var sqlLiteral: String {
        return absoluteString
    }
}
