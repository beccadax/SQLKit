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

public struct PGTime {
    public var hour: Int
    public var minute: Int
    public var second: Decimal
    public var timeZone: Zone?
    
    public typealias Zone = (hours: Int, minutes: Int)
}

public enum PGTimestamp {
    case distantPast
    case timestamp(era: PGDate.Era, year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Decimal, timeZone: PGTime.Zone?)
    case distantFuture
}

extension PGTimestamp {
    public init(date: PGDate, time: PGTime?) {
        switch (date, time) {
        case (.distantPast, _):
            self = .distantPast
        case (.distantFuture, _):
            self = .distantFuture
        case let (.date(era, year, month, day), time?):
            self = .timestamp(era: era, year: year, month: month, day: day, hour: time.hour, minute: time.minute, second: time.second, timeZone: time.timeZone)
        case let (.date(era, year, month, day), nil):
            self = .timestamp(era: era, year: year, month: month, day: day, hour: 0, minute: 0, second: 0, timeZone: nil)
        }
    }
    
    public var date: PGDate {
        get {
            switch self {
            case .distantPast:
                return .distantPast
            case .timestamp(let era, let year, let month, let day, _, _, _, _):
                return .date(era: era, year: year, month: month, day: day)
            case .distantFuture:
                return .distantFuture
            }
        }
        set {
            self = PGTimestamp(date: newValue, time: time)
        }
    }
    
    public var time: PGTime? {
        get {
            guard case let .timestamp(_, _, _, _, hour, minute, second, timeZone) = self else {
                return nil
            }
            
            return PGTime(hour: hour, minute: minute, second: second, timeZone: timeZone)
        }
        set {
            self = PGTimestamp(date: date, time: newValue)
        }
    }
}

extension PGTimestamp {
    public init(_ date: Date) {
        switch date {
        case Date.distantPast:
            self = .distantPast
        case Date.distantFuture:
            self = .distantFuture
        default:
            let components = Calendar.gregorian.dateComponents([.era, .year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone], from: date)
            self = PGTimestamp(components)!
        }
    }
    
    public init?(_ components: DateComponents) {
        guard let date = PGDate(components), let time = PGTime(components) else {
            return nil
        }
        
        self.init(date: date, time: time)
    }
}

extension PGDate {
    public init?(_ components: DateComponents) {
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        
        self = .date(era: components.era.flatMap(Era.init(rawValue:)) ?? .ad, year: year, month: month, day: day)
    }
}

extension PGTime {
    public init?(_ components: DateComponents) {
        guard let hour = components.hour, let minute = components.minute, let second = components.second, let nanosecond = components.nanosecond else {
            return nil
        }
        
        self.hour = hour
        self.minute = minute
        
        self.second = Decimal(second) + Decimal(nanosecond) / pow(10, DateComponents.nanosecondDigits)
        
        let referenceDate = components.date ?? Calendar.gregorian.date(from: components) ?? Date()
        let timeZoneOffset = components.timeZone.map { $0.secondsFromGMT(for: referenceDate) / 60 }
        self.timeZone = timeZoneOffset.map { (hours: $0 / 60, minutes: $0 % 60) }
    }
}

extension DateComponents {
    public init?(_ date: PGDate) {
        guard case let .date(era, year, month, day) = date else {
            return nil
        }
        
        self.init(era: era.rawValue, year: year, month: month, day: day)
    }
    
    public init(_ time: PGTime) {
        let second = Int(time.second)
        let nanosecond = Int((time.second - Decimal(second)) * pow(10, DateComponents.nanosecondDigits))
        
        let timeZoneOffset = time.timeZone.map { tz in (tz.hours * 60 + tz.minutes) * 60 }
        let timeZone = timeZoneOffset.flatMap(TimeZone.init(secondsFromGMT:))
        
        self.init(timeZone: timeZone, hour: time.hour, minute: time.minute, second: second, nanosecond: nanosecond)
    }
    
    public init?(_ timestamp: PGTimestamp) {
        guard let dateComps = DateComponents(timestamp.date) else {
            return nil
        }
        let timeComps = DateComponents(timestamp.time!)
        
        self.init(timeZone: timeComps.timeZone, era: dateComps.era, year: dateComps.year, month: dateComps.month, day: dateComps.day, hour: timeComps.hour, minute: timeComps.minute, second: timeComps.second, nanosecond: timeComps.nanosecond)
    }
}

extension Date {
    init?(_ timestamp: PGTimestamp) {
        guard let comps = DateComponents(timestamp) else {
            return nil
        }
        guard let date = Calendar.gregorian.date(from: comps) else {
            return nil
        }
        self = date
    }
}

extension Int {
    init(_ decimal: Decimal) {
        self = NSDecimalNumber(decimal: decimal).intValue
    }
}
