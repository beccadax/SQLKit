//
//  PGTime.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

public struct PGTime {
    public var hour: Int
    public var minute: Int
    public var second: Decimal
    public var timeZone: Zone?
    
    public typealias Zone = (hours: Int, minutes: Int)
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
