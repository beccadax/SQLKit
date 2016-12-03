//
//  Value.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/30/16.
//
//

import Foundation
import libpq

public enum PGRawValue {
    public enum Format: Int32 {
        case textual = 0
        case binary = 1
    }
    
    case textual(String)
    case binary(Data)
    
    public init(data: Data, format: Format) {
        switch format {
        case .textual:
            self = .textual(String(data: data, encoding: .utf8)!)
        case .binary:
            self = .binary(data)
        }
    }
    
    public var data: Data {
        switch self {
        case .textual(let string):
            var data = string.data(using: .utf8)!
            data.append(0)
            return data
            
        case .binary(let data):
            return data
        }
    }
    
    public var format: Format {
        switch self {
        case .textual:
            return .textual
        case .binary:
            return .binary
        }
    }
}

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

enum PGConversionError: Error {
    case invalidNumber(String)
    
    case invalidDateComponents(underlying: Error, at: String.Index, in: String)
    case invalidDate(underlying: Error, at: String.Index, in: String)
    case unexpectedDateCharacter(Character, during: Any)
    case invalidTimeZoneOffset(String)
    case nonexistentDate(DateComponents)
    case earlyTermination(during: Any)
    
    case invalidInterval(underlying: Error, at: String.Index, in: String)
    case unknownIntervalUnit(Character)
    case redundantQuantity(oldValue: Int, newValue: Int, for: PGInterval.Component)
    case unitlessQuantity(Int)
    case missingIntervalPrefix(Character)
}

extension Int: PGValue {
    public static let preferredPGType = PGType.int8

    public init(textualRawPGValue text: String) throws {
        guard let value = Int(text) else {
            throw PGConversionError.invalidNumber(text)
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
            throw PGConversionError.invalidNumber(text)
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
            throw PGConversionError.invalidNumber(text)
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

func rawValues(of values: [PGValue?]) -> ([PGRawValue?], [PGType?]) {
    var rawValues: [PGRawValue?] = []
    var types: [PGType?] = []
    
    for value in values {
        rawValues.append(value?.rawPGValue)
        types.append(value.map { type(of: $0).preferredPGType })
    }
    
    return (rawValues, types)
}
