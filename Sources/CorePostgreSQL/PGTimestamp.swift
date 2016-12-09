//
//  PGTimestamp.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

/// Representation of a PostgreSQL TIMESTAMP value, identifying a particular   
/// moment in time using a Gregorian date and time of day.
/// 
/// A `PGTimestamp` consists of a `date` and `time`. The `time` may or may not 
/// include a time zone, and the `date` may or may not be `distantPast` or 
/// `distantFuture`.
/// 
/// A timestamp with a `distantPast` or `distantFuture` date still has a `time` 
/// property, but that time isn't included when the timestamp is translated into a 
/// form understood by the PostgreSQL server.
public struct PGTimestamp {
    /// A timestamp with a date that comes before all other dates.
    public static var distantPast = PGTimestamp(date: .distantPast)
    /// A timestamp with a date that comes after all other dates.
    public static var distantFuture = PGTimestamp(date: .distantFuture)
    
    /// Creates a timestamp from a given `date` and `time`.
    /// 
    /// - Parameter date: The date to use; defaults to 0000-00-00 AD.
    /// - Parameter time: The time to use; defaults to 00:00:00 with no time zone.
    public init(date: PGDate = PGDate(), time: PGTime = PGTime()) {
        self.date = date
        self.time = time
    }
    
    /// The date portion of this timestamp.
    public var date: PGDate
    /// The itme portion of this timestamp.
    public var time: PGTime
}

extension PGTimestamp {
    /// Creates a timestamp corresponding to the indicated date.
    /// 
    /// - Parameter date: A Foundation `Date`. If this date is equal to  
    ///               `Date.distantPast` or `Date.distantFuture`, the resulting 
    ///               timestamp will have a date of `PGDate.distantPast` or 
    ///               `PGDate.distantFuture`, respectively. (Note, however,  that  
    ///               these constants don't actually have equal values.)
    public init(_ date: Date) {
        switch date {
        case Date.distantPast:
            self.init(date: .distantPast)
        case Date.distantFuture:
            self.init(date: .distantFuture)
        default:
            let components = Calendar.gregorian.dateComponents([.era, .year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone], from: date)
            self.init(components)!
        }
    }
    
    /// Creates a timestamp corresponding to the indicated `DateComponents`.
    /// 
    /// - Parameter components: The `DateComponents` instance to convert. This 
    ///                must include at least the `year`, `month`, `day`, `hour`, and 
    ///                `minute` fields. The `era`, `second`, `nanosecond`, and 
    ///                `timeZone` fields will also be used if present.
    public init?(_ components: DateComponents) {
        guard let date = PGDate(components), let time = PGTime(components) else {
            return nil
        }
        
        self.init(date: date, time: time)
    }
}

extension DateComponents {
    /// Creates date components corresponding to the indicated `PGTimestamp`.
    /// 
    /// - Parameter timestamp: The timestamp to convert. `timestamp.date` must 
    ///               not be `distantPast` or `distantFuture`.
    public init?(_ timestamp: PGTimestamp) {
        guard let dateComps = DateComponents(timestamp.date) else {
            return nil
        }
        let timeComps = DateComponents(timestamp.time)
        
        self.init(timeZone: timeComps.timeZone, era: dateComps.era, year: dateComps.year, month: dateComps.month, day: dateComps.day, hour: timeComps.hour, minute: timeComps.minute, second: timeComps.second, nanosecond: timeComps.nanosecond)
    }
}

extension Date {
    /// Creates a date corresponding to the indicated `PGTimestamp`.
    /// 
    /// - Parameter timestamp: The timestamp to convert. If `timestamp.date` is 
    ///               `distantPast` or `distantFuture`, the resulting 
    ///               date will be `Date.distantPast` or `Date.distantFuture`, 
    ///               respectively. (Note, however,  that these constants don't 
    ///               actually have equal values.)
    public init?(_ timestamp: PGTimestamp) {
        switch timestamp.date {
        case .distantPast:
            self = Date.distantPast
        case .distantFuture:
            self = Date.distantFuture
        default:
            guard let comps = DateComponents(timestamp) else {
                return nil
            }
            guard let date = Calendar.gregorian.date(from: comps) else {
                return nil
            }
            self = date
        }
    }
}
