//
//  PGTime.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/4/16.
//
//

import Foundation

/// Representation of a PostgreSQL TIME value, identifying a particular moment in  
/// a day without a date.
/// 
/// A `PGTime` includes an hour, minute, second, and may include a time zone.
public struct PGTime {
    /// Creates a `PGTime` for the indicated time.
    /// 
    /// - Parameter hour: A zero-based, 24-hour hour of the day. Defaults to `0`.
    /// - Parameter minute: A zero-based minute during that hour. Defaults to `0`.
    /// - Parameter second: A zero-based second during that minute. Defaults to `0`.
    /// - Parameter timeZone: The time zone that the date is in, as a 
    ///               `PGTime.Zone` instance. Defaults to `nil`.
    public init(hour: Int = 0, minute: Int = 0, second: Decimal = 0, timeZone: Zone? = nil) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZone = timeZone
    }
    
    /// A zero-based, 24-hour hour of the day.
    public var hour: Int
    /// A zero-based minute during the `hour`.
    public var minute: Int
    /// A zero-based second during the `minute`. `second` is a `Decimal`; 
    /// PostgreSQL supports up to six digits of fractional seconds.
    public var second: Decimal
    /// The time zone that the date is in, if any. `nil` means the time zone is not 
    /// specified.
    public var timeZone: Zone?
}

extension PGTime {
    /// Create a time from the `DateComponents` instance.
    /// 
    /// - Parameter components: The `DateComponents` instance to convert. This  
    ///               must include at last `hour` and `minute` fields. The `second`, 
    ///               `nanosecond`, and `timeZone` fields will also be used if 
    ///               present.
    public init?(_ components: DateComponents) {
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        
        let second = components.second ?? 0
        let nanosecond = components.nanosecond ?? 0
        
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
    /// Create date components from the `PGTime` instance.
    /// 
    /// - Parameter date: The `PGTime` instance to convert.
    public init(_ time: PGTime) {
        let second = Int(time.second)
        let nanosecond = Int((time.second - Decimal(second)) * pow(10, DateComponents.nanosecondDigits))
        
        let timeZone = time.timeZone.flatMap(TimeZone.init)
        
        self.init(timeZone: timeZone, hour: time.hour, minute: time.minute, second: second, nanosecond: nanosecond)
    }
}

extension Int {
    init(_ decimal: Decimal) {
        self = NSDecimalNumber(decimal: decimal).intValue
    }
}
