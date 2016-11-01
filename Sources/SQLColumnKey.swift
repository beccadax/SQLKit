//
//  SQLColumnKey.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation

public protocol _SQLColumnKey: Hashable {
    associatedtype Value
    
    init(index: Int, name: String)
    
    var index: Int { get }
    var name: String { get }
    var valueType: Value.Type { get }
    var nullable: Bool { get }
}

public struct AnySQLColumnKey: Hashable {
    public let index: Int?
    public let name: String?
    public let valueType: Any.Type?
    public let nullable: Bool
    
    fileprivate var identity: (index: Int, name: String, valueType: ObjectIdentifier, nullable: Bool) {
        return (index ?? -1, name ?? "", valueType.map(ObjectIdentifier.init) ?? ObjectIdentifier(Never.self), nullable)
    }
    
    public static func == (lhs: AnySQLColumnKey, rhs: AnySQLColumnKey) -> Bool {
        return lhs.identity == rhs.identity
    }
    
    public static func == <Other: _SQLColumnKey>(lhs: AnySQLColumnKey, rhs: Other) -> Bool {
        return lhs.identity == rhs.identity
    }
    
    public static func == <Other: _SQLColumnKey>(lhs: Other, rhs: AnySQLColumnKey) -> Bool {
        return lhs.identity == rhs.identity
    }
    
    public var hashValue: Int {
        let identity = self.identity
        return identity.index.hashValue ^ identity.name.hashValue ^ identity.valueType.hashValue
    }
}

extension _SQLColumnKey {
    public init?(_ anyKey: AnySQLColumnKey) {
        guard anyKey.valueType == Value.self,
            let index = anyKey.index,
            let name = anyKey.name
        else {
                return nil
        }
        
        self.init(index: index, name: name)
        
        guard anyKey.valueType == valueType && anyKey.nullable == nullable else {
            return nil
        }
    }
    
    fileprivate var identity: (index: Int, name: String, valueType: ObjectIdentifier, nullable: Bool) {
        return (index, name, ObjectIdentifier(valueType), nullable)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identity == rhs.identity
    }
    
    public var hashValue: Int {
        let identity = self.identity
        return identity.index.hashValue ^ identity.name.hashValue ^ identity.valueType.hashValue ^ identity.nullable.hashValue
    }
}

public struct SQLColumnKey<Value: SQLValue>: _SQLColumnKey {
    public let index: Int
    public let name: String
    
    public init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    public var valueType: Value.Type {
        return Value.self
    }
    public var nullable: Bool {
        return false
    }
}

public struct SQLNullableColumnKey<Value: SQLValue>: _SQLColumnKey {
    public let index: Int
    public let name: String
    
    public init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    public var valueType: Value.Type {
        return Value.self
    }
    
    public var nullable: Bool {
        return true
    }
}

extension AnySQLColumnKey {
    public init<Other: _SQLColumnKey>(_ key: Other) {
        self.index = key.index
        self.name = key.name
        self.valueType = key.valueType
        self.nullable = key.nullable
    }
}

