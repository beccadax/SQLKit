//
//  SQLErrorLocalization.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/30/16.
//
//

import Foundation

// FIXME #7: NSLocalizedString is often used incorrectly
extension SQLColumnError: LocalizedError {
    private var reason: String {
        switch self {
        case .columnMissing:
            return NSLocalizedString("does not exist", comment: "")
            
        case let .columnNotConvertible(to: expectedType, from: actualType?):
            return NSLocalizedString("was of \(actualType), which cannot be converted to \(expectedType)", comment: "")
            
        case let .columnNotConvertible(to: expectedType, from: nil):
            return NSLocalizedString("was of a type which cannot be converted to \(expectedType)", comment: "")
        }
    }
    
    public var errorDescription: String? {
        return NSLocalizedString("The column could not be accessed because it \(reason).", comment: "")
    }
    
    public var failureReason: String? {
        return NSLocalizedString("It \(reason).", comment: "")
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .columnMissing:
            return NSLocalizedString("Ensure that the name or index is correct.", comment: "")
            
        case let .columnNotConvertible(to: expectedType, from: _):
            return NSLocalizedString("Ensure that \(expectedType) is supported by the SQL client and suts the data being stored into it.", comment: "")
        }
    }
}

// FIXME #7: NSLocalizedString is often used incorrectly
extension SQLValueError: LocalizedError {
    private var reason: String {
        switch self {
        case .valueNull:
            return NSLocalizedString("was unexpectedly null", comment: "")
            
        case let .stringNotConvertible(sqlLiteral, type):
            let shortValue = sqlLiteral.truncated(to: 30)
            
            return NSLocalizedString("\"\(shortValue)\" could not be converted to the desired type \(type)", comment: "")
            
        case let .typeUnsupportedByClient(valueType, client):
            return NSLocalizedString("\(client) does not support values of type \(valueType)", comment: "")
        }
    }
    
    public var errorDescription: String? {
        return NSLocalizedString("The value could not be accessed because it \(reason).", comment: "")
    }
    
    public var failureReason: String? {
        return NSLocalizedString("It \(reason).", comment: "")
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .valueNull:
            return NSLocalizedString("Check that the data is correct and the application handles all expected cases.", comment: "")
            
        case .stringNotConvertible:
            return NSLocalizedString("Ensure that the string is properly formed so that it can be parsed by the type.", comment: "")
        
        case .typeUnsupportedByClient:
            return NSLocalizedString("Make the type SQLStringConvertible to provide a string-based fallback, or choose a supported type.", comment: "")
        }
    }
}

// FIXME #7: NSLocalizedString is often used incorrectly
extension SQLError: LocalizedError {
    private var underlyingLocalizedFailureReason: String? {
        return underlying.flatMap { ($0 as NSError).localizedFailureReason }
    }
    
    private var underlyingLocalizedRecoverySuggestion: String? {
        return underlying.flatMap { ($0 as NSError).localizedRecoverySuggestion }
    }
    
    private var reason: String {
        switch self {
        case .connectionFailed:
            return NSLocalizedString("could not connect to the SQL database", comment: "")
            
        case .executionFailed:
            return NSLocalizedString("could not execute a SQL statement", comment: "")
            
        case .noRecordsFound:
            return NSLocalizedString("unexpectedly did not receive any records from a SQL query", comment: "")
            
        case .extraRecordsFound:
            return NSLocalizedString("unexpectedly received too many records from a SQL query", comment: "")
        
        case .columnInvalid(_, let key, _):
            return NSLocalizedString("could not access column \(key)", comment: "")
        
        case .valueInvalid(_, let key, _):
            return NSLocalizedString("could not access a value in column \(key)", comment: "")
        }
    }
    
    public var errorDescription: String? {
        if let underlyingReason = underlyingLocalizedFailureReason {
            return NSLocalizedString("The application \(reason). \(underlyingReason)", comment: "")
        }
        else {
            return NSLocalizedString("The application \(reason).", comment: "")
        }
    }
    
    public var failureReason: String? {
        if let underlyingReason = underlyingLocalizedFailureReason {
            return NSLocalizedString("It \(reason). \(underlyingReason)", comment: "")
        }
        else {
            return NSLocalizedString("It \(reason).", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        if let underlyingSuggestion = underlyingLocalizedRecoverySuggestion {
            return underlyingSuggestion
        }
        
        switch self {
        case .connectionFailed:
            return NSLocalizedString("Check that you are connected to the database and the connection URL is correct.", comment: "")
        
        case .executionFailed:
            return NSLocalizedString("Check that the statement's syntax is correct and all tables and columns are consistent with the schema.", comment: "")
        
        case .noRecordsFound:
            return NSLocalizedString("Make sure the database is not empty and is in a consistent state.", comment: "")
            
        case .extraRecordsFound:
            return NSLocalizedString("Make sure the database is in a consistent state.", comment: "")
            
        case .columnInvalid:
            return NSLocalizedString("Check that the code is consistent with the database schema and the values returned by the query.", comment: "")
            
        case .valueInvalid:
            return NSLocalizedString("Check that the code is consistent with the database schema and the values returned by the query, and make sure that the database is in a consistent state.", comment: "")
        }
    }
}

extension PoolError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .timedOut:
            return NSLocalizedString("The pool timed out waiting for a resource to be returned.", comment: "")
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .timedOut:
            return NSLocalizedString("It timed out waiting for a resource to be returned.", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .timedOut:
            return NSLocalizedString("Consider increasing the pool size or timeout period.", comment: "")
        }
    }
}
