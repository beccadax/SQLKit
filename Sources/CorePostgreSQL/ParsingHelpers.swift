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

extension AnyOf where Element: ExpressibleByUnicodeScalarLiteral {
    static var digits: AnyOf<Element> {
        return .init("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
    }
}

func ~= <Element: Hashable>(pattern: AnyOf<Element>, candidate: Element) -> Bool {
    return pattern.candidates.contains(candidate)
}

struct ValueAccumulator {
    private var text = ""
    
    var isEmpty: Bool {
        return text.isEmpty
    }
    
    init() {}
    
    init(_ char: Character) {
        self.init()
        text.append(char)
    }
    
    func adding(_ char: Character) -> ValueAccumulator {
        var copy = self
        copy.text.append(char)
        return copy
    }
    
    func make<Value: PGValue>() throws -> Value {
        return try Value(textualRawPGValue: text)
    }
    
    func make() throws -> PGTime.Zone {
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
