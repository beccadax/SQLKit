//
//  ParsingHelpers.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/2/16.
//
//

import Foundation

struct AnyOf<Element: Hashable> {
    var candidates: Set<Element>
    
    init(_ candidates: Element...) {
        self.candidates = Set(candidates)
    }
}

func ~= <Element: Hashable>(pattern: AnyOf<Element>, candidate: Element) -> Bool {
    return pattern.candidates.contains(candidate)
}

struct NumberAccumulator {
    static let digits = AnyOf<Character>("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
    
    private var digits = ""
    
    var isEmpty: Bool {
        return digits.isEmpty
    }
    
    mutating func addDigit(_ char: Character) {
        digits.append(char)
    }
    
    mutating func make() throws -> Int {
        defer { digits = "" }
        return try Int(textualRawPGValue: digits)
    }
    
    mutating func make() throws -> Decimal {
        defer { digits = "" }
        return try Decimal(textualRawPGValue: digits)
    }
    
    mutating func make() throws -> PGTime.Zone {
        let timeCode = try self.make() as Int
        
        switch abs(timeCode) {
        case 0...12:
            // A `±hh` offset
            return (hours: timeCode, minutes: 0)
            
        case 100...1200 where 0..<60 ~= abs(timeCode) % 100:
            // A `±hhmm` offset
            return (hours: timeCode / 100, minutes: timeCode % 100)
            
        default:
            throw PGError.invalidTimeZoneOffset(timeCode)
        }
    }
}
