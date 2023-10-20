//
//  Int+Formatted.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/2/16.
//
//

import Foundation

protocol NumericFormattable: ExpressibleByIntegerLiteral {
    func formatted(digits: Int) -> String
}

extension Int: NumericFormattable {
    func formatted(digits: Int) -> String {
        let sign = self < 0 ? "-" : ""
        
        let base = String(abs(self))
        
        let extraCount = digits - base.count
        guard extraCount > 0 else {
            return base
        }
        
        let extra = String(repeating: "0", count: extraCount)
        return sign + extra + base
    }
}

extension Decimal: NumericFormattable {
    func formatted(digits: Int) -> String {
        let sign = self < 0 ? "-" : ""
        
        let base = String(describing: abs(self))
        
        let wholeEndIndex = base.firstIndex(of: ".") ?? base.endIndex
        let extraCount = digits - base.distance(from: base.startIndex, to: wholeEndIndex)
        
        guard extraCount > 0 else {
            return base
        }
        
        let extra = String(repeating: "0", count: extraCount)
        return sign + extra + base
    }
}

func f<Num: NumericFormattable>(_ number: Num, digits: Int = 2) -> String {
    return number.formatted(digits: digits)
}

