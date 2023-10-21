//
//  ParsingHelpers.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/2/16.
//
//

import Foundation

/// Used in a pattern match, this type will match if any of its elements is equal 
/// to the value.
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
}
