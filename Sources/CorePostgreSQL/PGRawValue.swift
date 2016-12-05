//
//  PGRawValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

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

func rawValues(of values: [PGValue?]) -> ([PGRawValue?], [PGType?]) {
    var rawValues: [PGRawValue?] = []
    var types: [PGType?] = []
    
    for value in values {
        rawValues.append(value?.rawPGValue)
        types.append(value.map { type(of: $0).preferredPGType })
    }
    
    return (rawValues, types)
}
