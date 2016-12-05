//
//  PGValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/30/16.
//
//

import Foundation
import libpq

public protocol PGValue {
    static var preferredPGType: PGType { get }
    
    init(textualRawPGValue text: String) throws
    var rawPGValue: PGRawValue { get }
    
    // Implemented by extension; do not override.
    init(rawPGValue: PGRawValue) throws
}

extension PGValue {
    public init(rawPGValue: PGRawValue) throws {
        switch rawPGValue {
        case .textual(let text):
            try self.init(textualRawPGValue: text)
            
        case .binary(_):
            fatalError("Type does not support binary values.")
        }
    }
}

public protocol PGBinaryValue: PGValue {
    init(binaryRawPGValue bytes: Data) throws
}

extension PGBinaryValue {
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
        let timestamp = PGTimestamp(date: self, time: nil)
        return .textual(PGDate.formatter.string(from: timestamp)!)
    }
}

extension PGTime: PGValue {
    public static let preferredPGType = PGType.timestampTZ
    private static let formatter = PGTimestampFormatter(style: .time)
    
    public init(textualRawPGValue text: String) throws {
        let timestamp = try PGTime.formatter.timestamp(from: text)
        self = timestamp.time!
    }
    
    public var rawPGValue: PGRawValue {
        let timestamp = PGTimestamp(date: .date(era: .ad, year: 0, month: 0, day: 0), time: self)
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
