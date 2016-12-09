//
//  PGDate.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/2/16.
//
//

import Foundation

/// Representation of a PostgreSQL DATE value, identifying a particular day in the 
/// Gregorian calendar without a time.
/// 
/// A `PGDate` includes a day, month, year, and era (A.D. or B.C.). There are 
/// also two special `PGDate`s, `distantPast` and `distantFuture`, which do not 
/// have these fields and come before or after every other date.
public enum PGDate {
    /// Represents whether a date is in A.D. or B.C.
    public enum Era: Int {
        /// Date is in the B.C. era.
        case bc = 0
        /// Date is in the A.D. era.
        case ad = 1
    }
    
    /// A date before all other dates. PostgreSQL calls this `-infinity`.
    case distantPast
    /// An ordinary date, as opposed to `distantPast` or `distantFuture`. 
    case date(era: Era, year: Int, month: Int, day: Int)
    /// A date after all other dates. PostgreSQL calls this `infinity`.
    case distantFuture
    
    /// Create an ordinary date.
    /// 
    /// - Parameter era: The era. Defaults to `ad`.
    /// - Parameter year: The year. Defaults to `0`.
    /// - Parameter month: The month. Defaults to `0`.
    /// - Parameter day: The day. Defaults to `0`.
    init(era: Era = .ad, year: Int = 0, month: Int = 0, day: Int = 0) {
        self = .date(era: .ad, year: year, month: month, day: day)
    }
}

extension PGDate {
    /// Whether the year is in A.D. or B.C.
    public var era: Era {
        get {
            return properties.era
        }
        set {
            properties.era = newValue
        }
    }
    
    /// The year of the date. Valid values are from `1` to `Int.max`, though this 
    /// is not enforced.
    public var year: Int {
        get {
            return properties.year
        }
        set {
            properties.year = newValue
        }
    }
    
    /// The month of the date. Valid values are from `1` to `12`, though this 
    /// is not enforced.
    public var month: Int {
        get {
            return properties.month
        }
        set {
            properties.month = newValue
        }
    }
    
    /// The day of the date. Valid values are from `1` to `31`, though this 
    /// is not enforced.
    public var day: Int {
        get {
            return properties.day
        }
        set {
            properties.day = newValue
        }
    }
    
    private var properties: (era: Era, year: Int, month: Int, day: Int) {
        get {
            guard case let .date(era, year, month, day) = self else {
                return (.ad, 0, 0, 0)
            }
            return (era, year, month, day)
        }
        set {
            self = .date(era: newValue.era, year: newValue.year, month: newValue.month, day: newValue.day)
        }
    }
}

extension PGDate {
    /// Create a date from the `DateComponents` instance.
    /// 
    /// - Parameter components: The `DateComponents` instance to convert. This  
    ///               must include at last `year`, `month`, and `day` fields.
    ///               The `era` field will also be used if present.
    public init?(_ components: DateComponents) {
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        
        let era = components.era.flatMap(Era.init(rawValue:)) ?? .ad
        self = .date(era: era, year: year, month: month, day: day)
    }
}

extension DateComponents {
    /// Create date components from the `PGDate` instance.
    /// 
    /// - Parameter date: The `PGDate` instance to convert. This must not be 
    ///               `PGDate.distantPast` or `PGDate.distantFuture`.
    public init?(_ date: PGDate) {
        guard case let .date(era, year, month, day) = date else {
            return nil
        }
        
        self.init(era: era.rawValue, year: year, month: month, day: day)
    }
}
