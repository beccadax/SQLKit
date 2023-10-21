//
//  Error.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/3/16.
//
//

import Foundation

/// Conforming types describe what a parser was doing at the point when a parse 
/// error occurred.
public protocol PGConversionParsingState {
    /// A user-understandable description of what a parser is doing.
    /// 
    /// In English, this will usually be a string that starts with a word like 
    /// "during", "while", "before", "after", etc. It is meant to be incorporated 
    /// into a larger sentence.
    var localizedStateDescription: String { get }
}

/// Errors thrown by CorePostgreSQL.
/// 
/// All `CorePostgreSQL` errors include a localized description; `executionFailed` 
/// errors also include localized failure reasons and recovery suggestions, drawn 
/// from the underlying PostgreSQL error message.
public enum PGError: Error {
    /// Connecting to a database failed.
    case connectionFailed(message: String)
    /// Executing a statement failed. The associated `PGResult.Status` intance 
    /// describes the failure in detail.
    case executionFailed(PGResult.Status)
    
    /// Attempting to parse the associated `String` as a `Bool` failed.
    case invalidBoolean(String)
    /// Attempting to parse the associated `String` as a number failed.
    case invalidNumber(String)
    /// Attempting to parse the associated `String` as a TIMESTAMP failed.
    /// The associated `Error` describes the failure in more detail; the 
    /// `String.Index` is the index at which the parse failed, and the 
    /// `PGConversionParsingState` describes the state of the timestamp parser 
    /// at failure.
    case invalidTimestamp(Error, at: String.Index, in: String, during: PGConversionParsingState)
    /// Attempting to parse the associated `String` as a DATE failed.
    /// The associated `Error` describes the failure in more detail; the 
    /// `String.Index` is the index at which the parse failed, and the 
    /// `PGConversionParsingState` describes the state of the timestamp parser 
    /// at failure.
    case invalidDate(Error, at: String.Index, in: String, during: PGConversionParsingState)
    /// Attempting to parse the associated `String` as a TIME failed.
    /// The associated `Error` describes the failure in more detail; the 
    /// `String.Index` is the index at which the parse failed, and the 
    /// `PGConversionParsingState` describes the state of the timestamp parser 
    /// at failure.
    case invalidTime(Error, at: String.Index, in: String, during: PGConversionParsingState)
    /// Attempting to parse the associated `String` as an INTERVAL failed.
    /// The associated `Error` describes the failure in more detail; the 
    /// `String.Index` is the index at which the parse failed, and the 
    /// `PGConversionParsingState` describes the state of the timestamp parser 
    /// at failure.
    case invalidInterval(Error, at: String.Index, in: String, during: PGConversionParsingState)
    
    /// Parsing failed because it encountered an unexpected character.
    case unexpectedCharacter(Character)
    /// Parsing failed because the digits in a TIME or TIMESTAMP's time zone offset  
    /// were not in range.
    case invalidTimeZoneOffset(Int)
    /// Parsing failed because the string ended before a complete value was parsed.
    case earlyTermination
    
    /// Parsing a PGInterval failed because the `PGInterval.Component` had two 
    /// conflicting values, `oldValue` and `newValue`.
    case redundantQuantity(oldValue: Int, newValue: Int, for: PGInterval.Component)
    /// Parsing a PGInterval failed because the `Int` did not have a unit attached 
    /// to it.
    case unitlessQuantity(Int)
}

extension PGError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .connectionFailed(message):
            return message
        
        case let .executionFailed(status):
            return status[.localizedPrimaryMessage]
            
        case .invalidBoolean(let string):
            return NSLocalizedString("Could not parse '\(string)' into a boolean.", comment: "")
            
        case .invalidNumber(let digits):
            return NSLocalizedString("Could not parse '\(digits)' into a number.", comment: "")
            
        case let .invalidTimestamp(error, at: _, in: _, during: state):
            return NSLocalizedString("Error \(state.localizedStateDescription) in a timestamp: \(error.localizedDescription)", comment: "")
        
        case let .invalidDate(error, at: _, in: _, during: state):
            return NSLocalizedString("Error \(state.localizedStateDescription) in a date: \(error.localizedDescription)", comment: "")
            
        case let .invalidTime(error, at: _, in: _, during: state):
            return NSLocalizedString("Error \(state.localizedStateDescription) in a time: \(error.localizedDescription)", comment: "")
            
        case let .invalidInterval(error, at: _, in: _, during: state):
            return NSLocalizedString("Error \(state.localizedStateDescription) in an interval: \(error.localizedDescription)", comment: "")
            
        case .unexpectedCharacter(let char):
            return NSLocalizedString("Unexpectedly encountered a '\(char)'.", comment: "")
            
        case .invalidTimeZoneOffset(let offset):
            return NSLocalizedString("'\(offset)' is not a valid time zone.", comment: "")
            
        case .earlyTermination:
            return NSLocalizedString("Unexpectedly reached the end of the string.", comment: "")
            
        case let .redundantQuantity(oldValue, newValue, for: component):
            return NSLocalizedString("It specified both \(oldValue) and \(newValue) for the \(component).", comment: "")
            
        case .unitlessQuantity(let number):
            return NSLocalizedString("No unit was specified for the number \(number).", comment: "")
        }
    }
    
    public var failureReason: String? {
        guard case .executionFailed(let status) = self else {
            return nil
        }
        return status[.localizedDetailMessage]
    }
    
    public var recoverySuggestion: String? {
        guard case .executionFailed(let status) = self else {
            return nil
        }
        return status[.localizedHintMessage]
    }
}
