//
//  PGRawValue.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

/// Represents a raw value in the format in which it will be given to `libpq`.
/// 
/// A `PGRawValue` can be in either `textual` or `binary` format; in both cases, 
/// correctly formatting the value requires detailed knowledge of PostgreSQL. 
/// The `PGValue` protocol represents a type which `CorePostgreSQL` can 
/// automatically convert to or from a `PGRawValue`. Usually, you should use 
/// `PGValue`s and depend on this automatic conversion rather than constructing 
/// and providing `PGRawValue`s yourself.
public enum PGRawValue {
    /// Describes the format of a raw value—either `textual` or `binary`—in the 
    /// abstract, without data attached.
    /// 
    /// The raw value of `PGRawValue.Format` is `0` for `textual` or `1` for 
    /// `binary`, matching a convention in `libpq` APIs.
    public enum Format: Int32 {
        /// The raw value is in textual format. Textual values are sent to 
        /// PostgreSQL as UTF-8 strings and cannot contain any null characters.
        /// They should not be escaped or quoted.
        case textual = 0
        /// The raw value is in binary format. Binary values are sent to 
        /// PostgreSQL as raw bytes and may contain null bytes. They must be in 
        /// PostgreSQL's internal format for the type in question.
        case binary = 1
    }
    
    /// A raw value in textual format. Textual values are sent to 
    /// PostgreSQL as UTF-8 strings and cannot contain any null characters.
    /// They should not be escaped or quoted.
    case textual(String)
    /// A raw value in binary format. Binary values are sent to 
    /// PostgreSQL as raw bytes and may contain null bytes. They must be in 
    /// PostgreSQL's internal format for the type in question.
    case binary(Data)
    
    /// Creates a raw value of the `format` indicated based on the provided `data`.
    public init(data: Data, format: Format) {
        switch format {
        case .textual:
            self = .textual(String(data: data, encoding: .utf8)!)
        case .binary:
            self = .binary(data)
        }
    }
    
    /// A byte buffer containing the contents of the raw value, ready to be 
    /// provided to PostgreSQL.
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
    
    /// The format of the raw value without any associated data.
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
