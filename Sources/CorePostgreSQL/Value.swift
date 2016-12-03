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
    case unexpectedDateCharacter(Character, during: Calendar.Component)
    case invalidTimeZoneOffset(String)
    case nonexistentDate(DateComponents)
    
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

extension Date: PGValue {
    public static let preferredPGType = PGType.timestampTZ
        
    public init(textualRawPGValue text: String) throws {
        let components = try DateComponents(textualRawPGValue: text)
        guard let date = Calendar.gregorian.date(from: components) else {
            throw PGConversionError.nonexistentDate(components)
        }
        self = date
    }

    public var rawPGValue: PGRawValue {
        let components = Calendar.gregorian.dateComponents(in: .utc, from: self)
        assert(components.timeZone != nil, "Need Calendar.dateComponents(in:from:) to fill in the time zone")
        return components.rawPGValue
    }
}

extension DateComponents: PGValue {
    public static let preferredPGType = PGType.timestampTZ
    
    private static let formatter = PGDateFormatter()
    
    public init(textualRawPGValue text: String) throws {
        self = try DateComponents.formatter.dateComponents(from: text)
    }
    
    public var rawPGValue: PGRawValue {
        return .textual(DateComponents.formatter.string(from: self))
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
