//
//  PGDate.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/2/16.
//
//

import Foundation

/// Representation of a PostgreSQL DATE value.
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
    
    /// Whether the year is in A.D. or B.C.
    public var era: Era {
        get {
            guard case .date(let era, _, _, _) = self else {
                return .ad
            }
            return era
        }
        set {
            if case let .date(_, year, month, day) = self {
                self = .date(era: newValue, year: year, month: month, day: day)
            }
            else {
                self = .date(era: newValue, year: 0, month: 0, day: 0)
            }
        }
    }
    
    /// The year of the date. Valid values are from `1` to `Int.max`, though this 
    /// is not enforced.
    public var year: Int {
        get {
            guard case .date(_, let year, _, _) = self else {
                return 0
            }
            return year
        }
        set {
            if case let .date(era, _, month, day) = self {
                self = .date(era: era, year: newValue, month: month, day: day)
            }
            else {
                self = .date(era: .ad, year: newValue, month: 0, day: 0)
            }
        }
    }
    
    /// The month of the date. Valid values are from `1` to `12`, though this 
    /// is not enforced.
    public var month: Int {
        get {
            guard case .date(_, _, let month, _) = self else {
                return 0
            }
            return month
        }
        set {
            if case let .date(era, year, _, day) = self {
                self = .date(era: era, year: year, month: month, day: day)
            }
            else {
                self = .date(era: .ad, year: 0, month: newValue, day: 0)
            }
        }
    }
    
    /// The day of the date. Valid values are from `1` to `31`, though this 
    /// is not enforced.
    public var day: Int {
        get {
            guard case .date(_, _, _, let day) = self else {
                return 0
            }
            return day
        }
        set {
            if case let .date(era, year, month, _) = self {
                self = .date(era: era, year: year, month: month, day: newValue)
            }
            else {
                self = .date(era: .ad, year: 0, month: 0, day: newValue)
            }
        }
    }
}

extension PGDate {
    /// Create an ordinary date.
    /// 
    /// - Parameter era: The era. Defaults to `ad`.
    /// - Parameter year: The year. Defaults to `0`.
    /// - Parameter month: The month. Defaults to `0`.
    /// - Parameter day: The day. Defaults to `0`.
    init(era: Era = .ad, year: Int = 0, month: Int = 0, day: Int = 0) {
        self = .date(era: .ad, year: year, month: month, day: day)
    }
    
    /// Create a date from the `DateComponents` instance.
    /// 
    /// - Parameter components: The `DateComponents` instance to convert. This  
    ///               must include at last `year`, `month`, and `day` fields.
    public init?(_ components: DateComponents) {
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        
        self = .date(era: components.era.flatMap(Era.init(rawValue:)) ?? .ad, year: year, month: month, day: day)
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
