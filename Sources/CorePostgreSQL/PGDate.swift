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
    
    public var era: Era {
        get {
            guard case .date(let era, _, _, _) = self else {
                return .ad
            }
            return era
        }
        set {
            if case let .date(_, year, month, day) = self {
                self = .date(era: newValue, year: year, month: month, day: day)
            }
            else {
                self = .date(era: newValue, year: 0, month: 0, day: 0)
            }
        }
    }
    
    public var year: Int {
        get {
            guard case .date(_, let year, _, _) = self else {
                return 0
            }
            return year
        }
        set {
            if case let .date(era, _, month, day) = self {
                self = .date(era: era, year: newValue, month: month, day: day)
            }
            else {
                self = .date(era: .ad, year: newValue, month: 0, day: 0)
            }
        }
    }
    
    public var month: Int {
        get {
            guard case .date(_, _, let month, _) = self else {
                return 0
            }
            return month
        }
        set {
            if case let .date(era, year, _, day) = self {
                self = .date(era: era, year: year, month: month, day: day)
            }
            else {
                self = .date(era: .ad, year: 0, month: newValue, day: 0)
            }
        }
    }
    
    public var day: Int {
        get {
            guard case .date(_, _, _, let day) = self else {
                return 0
            }
            return day
        }
        set {
            if case let .date(era, year, month, _) = self {
                self = .date(era: era, year: year, month: month, day: newValue)
            }
            else {
                self = .date(era: .ad, year: 0, month: 0, day: newValue)
            }
        }
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
