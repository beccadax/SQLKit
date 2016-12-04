//
//  Error.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation

public protocol PGConversionParsingState {
    var localizedStateDescription: String { get }
}

public enum PGError: Error {
    case connectionFailed(message: String)
    case executionFailed(PGResult.Error)
    
    case invalidBoolean(String)
    case invalidNumber(String)
    case invalidTimestamp(Error, at: String.Index, in: String, during: PGConversionParsingState)
    case invalidDate(Error, at: String.Index, in: String, during: PGConversionParsingState)
    case invalidTime(Error, at: String.Index, in: String, during: PGConversionParsingState)
    case invalidInterval(Error, at: String.Index, in: String, during: PGConversionParsingState)
    
    case unexpectedCharacter(Character)
    case invalidTimeZoneOffset(Int)
    case earlyTermination
    
    case redundantQuantity(oldValue: Int, newValue: Int, for: PGInterval.Component)
    case unitlessQuantity(Int)
}

extension PGConversionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
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
}
