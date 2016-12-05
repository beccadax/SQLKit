//
//  PGTime.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

public struct PGTime {
    public init(hour: Int = 0, minute: Int = 0, second: Decimal = 0, timeZone: Zone? = nil) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZone = timeZone
    }
    
    public var hour: Int
    public var minute: Int
    public var second: Decimal
    public var timeZone: Zone?
    
    public struct Zone {
        public var hours: Int
        public var minutes: Int
        
        public init(hours: Int, minutes: Int) {
            self.hours = hours
            self.minutes = minutes
        }
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
        self.timeZone = timeZoneOffset.map { Zone(hours: $0 / 60, minutes: $0 % 60) }
    }
}
