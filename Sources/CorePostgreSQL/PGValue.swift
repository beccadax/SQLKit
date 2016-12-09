//
//  PGValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/30/16.
//
//

import Foundation
import libpq

/// Conforming types can be converted to and from a `PGRawValue`.
/// 
/// `PGValue` is the primary way you should get data in and out of PostgreSQL. 
/// It leverages `CorePostgreSQL`'s detailed knowledge of how PostgreSQL formats 
/// values to ensure that all data sent to PostgreSQL is in a format it will 
/// understand and all data received from PostgreSQL will be parsed with knowledge 
/// of any edge cases or obscure syntax.
/// 
/// Conforming to `PGValue` alone only guarantees that the value can understand 
/// raw values received in `textual` format. Types which know how to parse `binary` 
/// format should conform to `PGBinaryValue`.
/// 
/// Conforming types must be able to convert all values of `Self` into a 
/// `PGRawValue`. Conversion back may in some circumstances cause an error.
public protocol PGValue {
    /// The PostgreSQL type which most closely corresponds to this type.
    /// 
    /// The `preferredPGType` should be able to express all values of `Self` as 
    /// accurately as possible. For instance, you would not give `Double` a 
    /// `preferredPGType` of `numeric`, because `numeric` is an exact decimal 
    /// number whereas `Double` is an approximate binary number.  
    static var preferredPGType: PGType { get }
    
    /// Creates an instance of `Self` from the contents of a textual raw value.
    /// 
    /// - Throws: If `text` is ill-formed or conversion otherwise fails.
    /// - Note: Conforming type should implement this initializer, but you will 
    ///          usually want to call the `init(rawPGValue:)` initializer instead of 
    ///          this one.
    init(textualRawPGValue text: String) throws
    
    /// Creates a `PGRawValue` from `Self`.
    /// 
    /// - Note: Conforming types may return a `binary` raw value from this 
    ///          property even if they don't conform to `PGBinaryValue`.
    var rawPGValue: PGRawValue { get }
    
    // Implemented by extension; do not override.
    /// Creates an instance of `Self` from the `rawValue`.
    /// 
    /// - Precondition: `rawValue` is not in binary format unless `Self` also 
    ///                   conforms to `PGBinaryValue`.
    /// 
    /// - Note: Conforming types should implement `init(textualRawPGValue:)` 
    ///           instead of this initializer, but you should usually call this one.
    init(rawPGValue: PGRawValue) throws
}

extension PGValue {
    /// Creates an instance of `Self` from the `rawValue`.
    /// 
    /// - Precondition: `rawValue` is not in binary format unless `Self` also 
    ///                   conforms to `PGBinaryValue`.
    /// 
    /// - Note: Conforming types should implement `init(textualRawPGValue:)` 
    ///           instead of this initializer, but you should usually call this one.
    public init(rawPGValue: PGRawValue) throws {
        switch rawPGValue {
        case .textual(let text):
            try self.init(textualRawPGValue: text)
            
        case .binary(_):
            fatalError("Type does not support binary values.")
        }
    }
}

/// Conforming types can be converted to and from a `PGRawValue`, and support 
/// `PGRawValue`s in both textual and binary formats.
/// 
/// Conforming types must be able to convert all values of `Self` into a 
/// `PGRawValue`. Conversion back may in some circumstances cause an error.
public protocol PGBinaryValue: PGValue {
    /// Creates an instance of `Self` from the contents of a binary raw value.
    /// 
    /// - Throws: If `bytes` are ill-formed or conversion otherwise fails.
    /// - Note: Conforming type should implement this initializer, but you will 
    ///          usually want to call the `init(rawPGValue:)` initializer instead of 
    ///          this one.
    init(binaryRawPGValue bytes: Data) throws
}

extension PGBinaryValue {
    /// Creates an instance of `Self` from the `rawValue`.
    /// 
    /// - Note: Conforming types should implement `init(textualRawPGValue:)` and 
    ///          init(binaryRawPGValue:)` instead of this initializer, but you should 
    ///          usually call this one.
    public init(rawPGValue: PGRawValue) throws {
        switch rawPGValue {
        case .textual(let text):
            try self.init(textualRawPGValue: text)
            
        case .binary(let bytes):
            try self.init(binaryRawPGValue: bytes)
        }
    }
}

extension String: PGValue {
    public static let preferredPGType = PGType.text
    
    public init(textualRawPGValue text: String) {
        self = text
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(self)
    }
}

extension Data: PGBinaryValue {
    public static let preferredPGType = PGType.byteA
    
    public init(textualRawPGValue text: String) {
        var count: Int = 0
        let bytes = PQunescapeBytea(text, &count)!
        self.init(bytes: bytes, count: count)
    }
    
    public init(binaryRawPGValue bytes: Data) {
        self = bytes
    }
    
    public var rawPGValue: PGRawValue {
        return .binary(self)
    }
}

extension Bool: PGValue {
    public static let preferredPGType = PGType.boolean
    
    public init(textualRawPGValue text: String) throws {
        switch text {
        case "t", "true", "y", "yes", "on", "1":
            self = true
        case "f", "false", "n", "no", "off", "0":
            self = false
        default:
            throw PGError.invalidBoolean(text)
        }
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(self ? "t" : "f")
    }
}

extension Int: PGValue {
    public static let preferredPGType = PGType.int8

    public init(textualRawPGValue text: String) throws {
        guard let value = Int(text) else {
            throw PGError.invalidNumber(text)
        }
        
        self = value
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(String(self))
    }
}

extension Double: PGValue {
    public static let preferredPGType = PGType.float8
    
    public init(textualRawPGValue text: String) throws {
        guard let value = Double(text) else {
            throw PGError.invalidNumber(text)
        }
        
        self = value
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(String(self))
    }
}

extension Decimal: PGValue {
    public static let preferredPGType = PGType.numeric
    
    public init(textualRawPGValue text: String) throws {
        guard let value = Decimal(string: text, locale: .posix) else {
            throw PGError.invalidNumber(text)
        }
        
        self = value
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(String(describing: self))
    }
}

extension PGTimestamp: PGValue {
    public static let preferredPGType = PGType.timestampTZ
    private static let formatter = PGTimestampFormatter(style: .timestamp)
    
    public init(textualRawPGValue text: String) throws {
        self = try PGTimestamp.formatter.timestamp(from: text)
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(PGTimestamp.formatter.string(from: self)!)
    }
}

extension PGDate: PGValue {
    public static let preferredPGType = PGType.timestampTZ
    private static let formatter = PGTimestampFormatter(style: .date)
    
    public init(textualRawPGValue text: String) throws {
        let timestamp = try PGDate.formatter.timestamp(from: text)
        self = timestamp.date
    }
    
    public var rawPGValue: PGRawValue {
        let timestamp = PGTimestamp(date: self)
        return .textual(PGDate.formatter.string(from: timestamp)!)
    }
}

extension PGTime: PGValue {
    public static let preferredPGType = PGType.timestampTZ
    private static let formatter = PGTimestampFormatter(style: .time)
    
    public init(textualRawPGValue text: String) throws {
        let timestamp = try PGTime.formatter.timestamp(from: text)
        self = timestamp.time
    }
    
    public var rawPGValue: PGRawValue {
        let timestamp = PGTimestamp(time: self)
        return .textual(PGTime.formatter.string(from: timestamp)!)
    }
}

extension PGInterval: PGValue {
    public static let preferredPGType = PGType.interval
    
    private static let formatter = PGIntervalFormatter()
    
    public init(textualRawPGValue text: String) throws {
        self.init()     // XXX compiler crash
        self = try PGInterval.formatter.interval(from: text)
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(PGInterval.formatter.string(from: self))
    }
}
