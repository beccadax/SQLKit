//
//  Value.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/30/16.
//
//

import Foundation

extension PostgreSQL {
    public enum RawValue {
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
        
        public var format: Format {
            switch self {
            case .textual:
                return .textual
            case .binary:
                return .binary
            }
        }
    }
}
