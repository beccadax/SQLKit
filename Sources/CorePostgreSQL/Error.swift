//
//  Error.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation

public protocol PGConversionErrorParsingState {
    
}

public enum PGConversionError: Error {
    case invalidNumber(String)
    
    case invalidDate(underlying: Error, at: String.Index, in: String)
    case unexpectedDateCharacter(Character, during: PGConversionErrorParsingState)
    case invalidTimeZoneOffset(String)
    case nonexistentDate(DateComponents)
    case earlyTermination(during: PGConversionErrorParsingState)
    
    case invalidInterval(Error, at: String.Index, in: String, during: PGConversionErrorParsingState)
    case unknownIntervalUnit(Character)
    case redundantQuantity(oldValue: Int, newValue: Int, for: PGInterval.Component)
    case unitlessQuantity(Int)
    case missingIntervalPrefix(Character?)
    case missingQuantity(Character)
}
