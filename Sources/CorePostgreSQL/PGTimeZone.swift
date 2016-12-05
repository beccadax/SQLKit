//
//  PGTimeZone.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

extension PGTime {
    public struct Zone {
        public var hours: Int
        public var minutes: Int
        
        public init(hours: Int, minutes: Int) {
            self.hours = hours
            self.minutes = minutes
        }
        
        public init(packedOffset timeCode: Int) throws {
            switch abs(timeCode) {
            case 0...12:
                // A `±hh` offset
                self.init(hours: timeCode, minutes: 0)
                
            case 100...1200 where 0..<60 ~= abs(timeCode) % 100:
                // A `±hhmm` offset
                self.init(hours: timeCode / 100, minutes: timeCode % 100)
                
            default:
                throw PGError.invalidTimeZoneOffset(timeCode)
            }
        }
    }
}

extension PGTime.Zone {
    init(_ timeZone: TimeZone, on referenceDate: Date) {
        let seconds = timeZone.secondsFromGMT(for: referenceDate) / 60
        let minutes = seconds / 60
        self.init(hours: minutes / 60, minutes: minutes % 60)
    }
}
