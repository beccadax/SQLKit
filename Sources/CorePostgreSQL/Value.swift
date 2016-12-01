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
}

public protocol PGBinaryValue: PGValue {
    init(binaryRawPGValue bytes: Data) throws
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

func rawValues(of values: [PGValue?]) -> ([PGRawValue?], [PGType?]) {
    var rawValues: [PGRawValue?] = []
    var types: [PGType?] = []
    
    for value in values {
        rawValues.append(value?.rawPGValue)
        types.append(value.map { type(of: $0).preferredPGType })
    }
    
    return (rawValues, types)
}
