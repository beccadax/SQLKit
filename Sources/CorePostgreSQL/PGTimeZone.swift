//
//  PGTimeZone.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

extension PGTime {
    /// Represents the time zone portion of a PostgreSQL TIME or TIMESTAMP value, 
    /// identifying the hour and minute offsets of a time zone.
    /// 
    /// A `PGTime.Zone` contains `hours` and `minutes` properties representing 
    /// those two portions of the time zone. If neither `hours` nor `minutes` is  
    /// `0`, both should have the same sign.
    public struct Zone {
        /// The number of hours that should be added to a UTC time, in combination 
        /// with `minutes`, to match this time zone.
        public var hours: Int
        
        /// The number of minutes that should be added to a UTC time, in 
        /// combination with `hours`, to match this time zone.
        public var minutes: Int
        
        /// Creates a time zone with the specified `hours` and `minutes` offset.
        ///
        /// - Parameter hours: The number of hours that should be added to a UTC 
        ///               time, in combination with with `minutes`, to match this 
        ///               time zone.
        /// - Parameter minutes: The number of minutes that should be added to a 
        ///               UTC time, in combination with `hours`, to match this time 
        ///               zone.
        /// 
        /// - Precondition: If neither `hours` nor `minutes` is `0`, both should 
        ///                   have the same sign.
        public init(hours: Int, minutes: Int) {
            precondition(minutes == 0 || hours == 0 || (hours < 0) == (minutes < 0), "Hours and minutes should have the same sign.")
            self.hours = hours
            self.minutes = minutes
        }
        
        /// Creates a time zone from an offset represented as a single integer in 
        /// either `±hh` or `±hhmm` format. 
        /// 
        /// - Parameter timeCode: An offset packed in either either `±hh` or 
        ///               `±hhmm` format. `timeCode`s between `-12` and `+12` 
        ///               will be interpreted as being in `±hh` format; time codes 
        ///               between `-1259` and `-15` or `15` and `-1259`, with 
        ///               the last two digits between `0` and `59`, will be 
        ///               interpreted as being in `±hhmm` format.
        /// 
        /// - Throws: `PGError.invalidTimeZoneOffset` if the `timeCode` does not 
        ///             fall into one of the permitted ranges.
        public init(packedOffset timeCode: Int) throws {
            switch abs(timeCode) {
            case 0...12:
                // A `±hh` offset
                self.init(hours: timeCode, minutes: 0)
                
            case 15...1259 where 0..<60 ~= abs(timeCode) % 100:
                // A `±hhmm` offset
                self.init(hours: timeCode / 100, minutes: timeCode % 100)
                
            default:
                throw PGError.invalidTimeZoneOffset(timeCode)
            }
        }
        
        /// Creates a time zone from an offset representing seconds from UTC.
        /// 
        /// - Parameter seconds: The offset in seconds.
        public init(secondsFromUTC seconds: Int) {
            let minutes = seconds / 60
            self.init(hours: minutes / 60, minutes: minutes % 60)
        }
        
        /// The total number of seconds that should be added to a UTC time 
        /// to match this time zone.
        public var secondsFromUTC: Int {
            get {
                return (hours * 60 + minutes) * 60
            }
            set {
                self = Zone(secondsFromUTC: newValue)
            }
        }
    }
}

extension PGTime.Zone {
    /// Creates a `PGTime.Zone` from a Foundation `TimeZone`.
    /// 
    /// - Parameter timeZone: The time zone to match the offset of.
    /// - Parameter referenceDate: The date to use to match the specific offset.
    public init(_ timeZone: TimeZone, on referenceDate: Date) {
        let seconds = timeZone.secondsFromGMT(for: referenceDate)
        self.init(secondsFromUTC: seconds)
    }
}

extension TimeZone {
    /// Creates a Foundation `TimeZone` from a `PGTime.Zone`.
    /// 
    /// - Parameter zone: The time zone to match the offset of.
    public init?(_ zone: PGTime.Zone) {
        self.init(secondsFromGMT: zone.secondsFromUTC)
    }
}
