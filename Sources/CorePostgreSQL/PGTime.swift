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
}

extension PGTime {
    public init?(_ components: DateComponents) {
        guard let hour = components.hour, let minute = components.minute, let second = components.second, let nanosecond = components.nanosecond else {
            return nil
        }
        
        self.hour = hour
        self.minute = minute
        
        self.second = Decimal(second) + Decimal(nanosecond) / pow(10, DateComponents.nanosecondDigits)
        
        if let timeZone = components.timeZone {
            let referenceDate = components.date ?? Calendar.gregorian.date(from: components) ?? Date()
            self.timeZone = Zone(timeZone, on: referenceDate)
        }
    }
}

extension DateComponents {
    public init(_ time: PGTime) {
        let second = Int(time.second)
        let nanosecond = Int((time.second - Decimal(second)) * pow(10, DateComponents.nanosecondDigits))
        
        let timeZoneOffset = time.timeZone.map { tz in (tz.hours * 60 + tz.minutes) * 60 }
        let timeZone = timeZoneOffset.flatMap(TimeZone.init(secondsFromGMT:))
        
        self.init(timeZone: timeZone, hour: time.hour, minute: time.minute, second: second, nanosecond: nanosecond)
    }
}
