//
//  PGTimestamp.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

public enum PGTimestamp {
    case distantPast
    case timestamp(era: PGDate.Era, year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Decimal, timeZone: PGTime.Zone?)
    case distantFuture
    
    init() {
        self = .timestamp(era: .ad, year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, timeZone: nil)
    }
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
