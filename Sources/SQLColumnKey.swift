//
//  SQLColumnKey.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation

public protocol AnySQLColumnKey {
    var index: Int { get }
    var name: String { get }
    var valueType: Any.Type { get }
    var nullable: Bool { get }
}

extension AnySQLColumnKey {
    fileprivate var identity: (Int, String, ObjectIdentifier, Bool) {
        return (index, name, ObjectIdentifier(valueType), nullable)
    }
    
    public var hashValue: Int {
        let id = identity
        return id.0.hashValue ^ id.1.hashValue ^ id.2.hashValue ^ id.3.hashValue
    }
}

public func == (lhs: AnySQLColumnKey, rhs: AnySQLColumnKey) -> Bool {
    return lhs.identity == rhs.identity
}

public func ~= (lhs: AnySQLColumnKey, rhs: AnySQLColumnKey) -> Bool {
    return lhs == rhs
}

extension AnySQLColumnKey where Self: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identity == rhs.identity
    }
}

public struct SQLColumnKey<Value: SQLValue>: AnySQLColumnKey, Hashable {
    public let index: Int
    public let name: String
    
    public init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    public var valueType: Any.Type {
        return Value.self
    }
    
    public var nullable: Bool {
        return false
    }
}

public struct SQLNullableColumnKey<Value: SQLValue>: AnySQLColumnKey, Hashable {
    public let index: Int
    public let name: String
    
    public init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    public var valueType: Any.Type {
        return Value.self
    }
    
    public var nullable: Bool {
        return true
    }
}
