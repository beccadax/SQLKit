//
//  PGDate.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/2/16.
//
//

import Foundation

public enum PGDate {
    public enum Era: Int {
        case bc = 0
        case ad = 1
    }
    
    case distantPast
    case date(era: Era, year: Int, month: Int, day: Int)
    case distantFuture
    
    @discardableResult mutating func setEra(to era: Era) -> Bool {
        guard case let .date(_, year, month, day) = self else {
            return false
        }
        self = .date(era: era, year: year, month: month, day: day)
        return true
    }
    
    @discardableResult mutating func setYear(to year: Int) -> Bool {
        guard case let .date(era, _, month, day) = self else {
            return false
        }
        self = .date(era: era, year: year, month: month, day: day)
        return true
    }
    
    @discardableResult mutating func setMonth(to month: Int) -> Bool {
        guard case let .date(era, year, _, day) = self else {
            return false
        }
        self = .date(era: era, year: year, month: month, day: day)
        return true
    }
    
    @discardableResult mutating func setDay(to day: Int) -> Bool {
        guard case let .date(era, year, month, _) = self else {
            return false
        }
        self = .date(era: era, year: year, month: month, day: day)
        return true
    }
}

extension PGDate {
    init(era: Era = .ad, year: Int = 0, month: Int = 0, day: Int = 0) {
        self = .date(era: .ad, year: year, month: month, day: day)
    }
    
    public init?(_ components: DateComponents) {
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        
        self = .date(era: components.era.flatMap(Era.init(rawValue:)) ?? .ad, year: year, month: month, day: day)
    }
}

extension DateComponents {
    public init?(_ date: PGDate) {
        guard case let .date(era, year, month, day) = date else {
            return nil
        }
        
        self.init(era: era.rawValue, year: year, month: month, day: day)
    }
}
