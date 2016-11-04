//
//  SQLColumnKey.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation

/// Represents a column in a `SQLQuery`; can be used to access that column in a 
/// `SQLRow`.
/// 
/// A column key encapsulates four pieces of information about the column: its 
/// name, its index in the row, its type, and whether or not it can be `NULL`. 
/// Column keys ensure that columns are looked up efficiently and type-safely.
/// 
/// To create a column key, use the `SQLQuery.columnKey(forName:as:)` or 
/// `columnKey(at:as:)` methods. To look up the value of a column in a row, use 
/// the `SQLRow.value(for:)` method.
/// 
/// Column keys are represented by two separate types, `SQLColumnKey` and 
/// `SQLNullableColumnKey`. Both types are generic on the column's value type.
/// For situations when either one is acceptable and the value type doesn't matter, 
/// `AnySQLColumnKey` is a protocol which both types conform to.
/// 
/// - Warning: Don't conform your own types to `AnySQLColumnKey`.
// 
// WORKAROUND: #5 Swift won't allow existentials to be made Equatable
public protocol AnySQLColumnKey {
    /// The index of the column.
    var index: Int { get }
    
    /// The name of the column.
    var name: String { get }
    
    /// The type of the column.
    var valueType: Any.Type { get }
    
    /// Whether the column's value is permitted to be `NULL`.
    var nullable: Bool { get }
}

extension AnySQLColumnKey where Self: Equatable {
    private var identity: (Int, String, ObjectIdentifier, Bool) {
        return (index, name, ObjectIdentifier(valueType), nullable)
    }
    
    public var hashValue: Int {
        let id = identity
        return id.0.hashValue ^ id.1.hashValue ^ id.2.hashValue ^ id.3.hashValue
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identity == rhs.identity
    }
}

/// Represents a column in a `SQLQuery`; can be used to access that column in a 
/// `SQLRow`.
/// 
/// A column key encapsulates four pieces of information about the column: its 
/// name, its index in the row, its type, and whether or not it can be `NULL`. 
/// Column keys ensure that columns are looked up efficiently and type-safely.
/// 
/// To create a column key, use the `SQLQuery.columnKey(forName:as:)` or 
/// `columnKey(at:as:)` methods. To look up the value of a column in a row, use 
/// the `SQLRow.value(for:)` method.
/// 
/// `SQLColumnKey` keys always represent non-`Optional` types. Nullable columns, 
/// which are represented with `Optional` types, are represented by 
/// `SQLNullableColumnKey`.
public struct SQLColumnKey<Value: SQLValue>: AnySQLColumnKey, Hashable {
    /// The index of the column.
    public let index: Int

    /// The name of the column.
    public let name: String
    
    /// Creates a column key with the indicated name and index.
    public init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    /// The type of the column.
    public var valueType: Any.Type {
        return Value.self
    }
    
    /// Whether the column's value is permitted to be `NULL`.
    public var nullable: Bool {
        return false
    }
}

/// Represents a column in a `SQLQuery`; can be used to access that column in a 
/// `SQLRow`.
/// 
/// A column key encapsulates four pieces of information about the column: its 
/// name, its index in the row, its type, and whether or not it can be `NULL`. 
/// Column keys ensure that columns are looked up efficiently and type-safely.
/// 
/// To create a column key, use the `SQLQuery.columnKey(forName:as:)` or 
/// `columnKey(at:as:)` methods. To look up the value of a column in a row, use 
/// the `SQLRow.value(for:)` method.
/// 
/// `SQLColumnKey` keys always represent non-`Optional` types. Nullable columns, 
/// which are represented with `Optional` types, are represented by 
/// `SQLNullableColumnKey`.
public struct SQLNullableColumnKey<Value: SQLValue>: AnySQLColumnKey, Hashable {
    /// The index of the column.
    public let index: Int
    
    /// The name of the column.
    public let name: String
    
    /// Creates a column key with the indicated name and index.
    public init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    /// The type of the column.
    public var valueType: Any.Type {
        return Value.self
    }
    
    /// Whether the column's value is permitted to be `NULL`.
    public var nullable: Bool {
        return true
    }
}

// WORKAROUND: #5 Swift won't allow existentials to be made Equatable
extension AnyHashable {
    /// Converts an `AnySQLColumnKey` into an `AnyHashable` value. All 
    /// `AnySQLColumnKey`s are `Hashable`, but this fact isn't expressed in the 
    /// type system.
    public init(_ key: AnySQLColumnKey) {
        self = key as! AnyHashable
    }
}

// WORKAROUND: #5 Swift won't allow existentials to be made Equatable
public func == (lhs: AnySQLColumnKey, rhs: AnySQLColumnKey) -> Bool {
    return AnyHashable(lhs) == AnyHashable(rhs)
}

// WORKAROUND: #5 Swift won't allow existentials to be made Equatable
public func != (lhs: AnySQLColumnKey, rhs: AnySQLColumnKey) -> Bool {
    return AnyHashable(lhs) != AnyHashable(rhs)
}

public func ~= (lhs: AnySQLColumnKey, rhs: AnySQLColumnKey) -> Bool {
    return lhs == rhs
}
