//
//  SQLStatement.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/29/16.
//
//

import Foundation

public protocol SQLStatementConvertible {
    var sqlStatement: SQLStatement { get }
}

public struct SQLStatement {
    public enum Segment {
        case raw (String)
        case parameter (SQLValue?)
        
        func replacingParameter(with mapping: (SQLValue?) throws -> String) rethrows -> String {
            switch self {
            case .raw(let sqlFragment):
                return sqlFragment
            case .parameter(let value):
                return try mapping(value)
            }
        }
    }
    
    public var segments: [Segment]
    fileprivate func onlyStringSegment() -> String {
        assert(segments.count == 1, "Literal fragment somehow has \(segments.count) segments")
        guard case .parameter(let str as String)? = segments.first else {
            assertionFailure("Literal fragment somehow has a \(segments) segment")
            return ""
        }
        return str
    }
    
    public init() {
        segments = []
    }
    
    public init(raw sql: String) {
        segments = [.raw(sql)]
    }
    
    public init(parameter value: SQLValue?) {
        segments = [.parameter(value)]
    }
    
    public init(_ convertible: SQLStatementConvertible) {
        self = convertible.sqlStatement
    }
    
    public init(_ statement: SQLStatement) {
        self = statement
    }
    
    public mutating func append(_ other: SQLStatementConvertible) {
        segments += SQLStatement(other).segments
    }
    
    public func rawSQLByReplacingParameters(with mapping: (_ value: SQLValue?) throws -> String) rethrows -> String {
        return try segments.map {
            try $0.replacingParameter(with: mapping)
        }.reduce("", +)
    }
}

extension SQLStatement {
    public mutating func append(raw sql: String) {
        append(SQLStatement(raw: sql))
    }
    
    public mutating func append(parameter value: SQLValue?) {
        append(SQLStatement(parameter: value))
    }
    
    public func appending(_ other: SQLStatementConvertible) -> SQLStatement {
        var copy = self
        copy.append(other)
        return copy
    }
    
    public func appending(raw sql: String) -> SQLStatement {
        var copy = self
        copy.append(raw: sql)
        return copy
    }
    
    public func appending(parameter value: SQLValue?) -> SQLStatement {
        var copy = self
        copy.append(parameter: value)
        return copy
    }
}
    
public func += (lhs: inout SQLStatement, rhs: SQLStatementConvertible) {
    lhs.append(rhs)
}

public func + (lhs: SQLStatementConvertible, rhs: SQLStatementConvertible) -> SQLStatement {
    var statement = SQLStatement(lhs)
    statement += rhs
    return statement
}

extension SQLStatement: SQLStatementConvertible {
    public var sqlStatement: SQLStatement {
        return self
    }
}

extension SQLStatement: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(raw: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(raw: value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.init(raw: value)
    }
}

extension SQLStatement: ExpressibleByStringInterpolation {
    public init(stringInterpolation strings: SQLStatement...) {
        self.init()
        for (n, substatement) in strings.enumerated() {
            if n % 2 == 0 {
                self.append(raw: substatement.onlyStringSegment())
            }
            else {
                self.append(substatement)
            }
        }
    }
    
    public init<T>(stringInterpolationSegment expr: T) {
        switch expr as Any? {
        case let value as SQLValue?:
            self.init(parameter: value)
        case let substatement as SQLStatementConvertible:
            self.init(substatement)
        default:
            self.init(parameter: String(describing: expr))
        }
    }
}

extension SQLStatement: Hashable {
    public static func == (lhs: SQLStatement, rhs: SQLStatement) -> Bool {
        guard lhs.segments.count == rhs.segments.count else {
            return false
        }
        
        for (l, r) in zip(lhs.segments, rhs.segments) {
            switch (l, r) {
            case (.raw(let lSQL), .raw(let rSQL)) where lSQL != rSQL:
                return false
                
            case (.parameter(let lValue), .parameter(let rValue)) where (lValue as? AnyHashable) != (rValue as? AnyHashable):
                return false
                
            case (.raw, .parameter), (.parameter, .raw):
                return false
                
            default:
                // This element doesn't disqualify us.
                break
            }
        }
        return true
    }
    
    public var hashValue: Int {
        return segments.reduce(0x501501) { hashValue, segment in
            switch segment {
            case .raw(let sql):
                return hashValue ^ sql.hashValue
            case .parameter(let value):
                return hashValue ^ ~((value as? AnyHashable)?.hashValue ?? 0)
            }
        }
    }
}
extension SQLStatement: CustomDebugStringConvertible {
    public var debugDescription: String {
        var lines: [String] = []
        
        let sql = rawSQLByReplacingParameters { value in
            let n = lines.count
            lines.append("    \(n): \(String(reflecting: value))")
            return "\\(\(n))"
        }
        lines.insert("SQLStatement: \(String(reflecting: sql))", at: 0)
        
        return lines.joined(separator: "\n")
    }
}

extension Collection where Iterator.Element: SQLStatementConvertible, SubSequence.Iterator.Element: SQLStatementConvertible {
    func joined(separator: SQLStatementConvertible) -> SQLStatement {
        let sep = SQLStatement(separator)
        guard let first = self.first else {
            return SQLStatement()
        }
        let rest = dropFirst()
        return rest.reduce(SQLStatement(first)) { left, right in left + sep + right }
    }
}
