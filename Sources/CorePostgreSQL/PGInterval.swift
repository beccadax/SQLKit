//
//  PGInterval.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/1/16.
//
//

import Foundation

/// Representation of a PostgreSQL INTERVAL value, expressing a length of time in 
/// multiple units.
/// 
/// A `PGInterval` contains several different `PGInterval.Component`s, each of 
/// which has an `Int` quantity associated with it. Omitted components have value 
/// `0`. A `PGInterval` can be created using a dictionary literal of component-value 
/// pairs.
public struct PGInterval {
    /// A component of a `PGInterval`. Each component is a unit of time 
    /// measurement, such as a year or minute.
    public enum Component: Hashable {
        static let all: [Component] = [ .year, .month, .week, .day, .hour, .minute, .second ]
        case year, month, week, day, hour, minute, second
    }
    
    fileprivate var components: [Component: Int] = [:]
    
    /// Accesses a particular component in the interval.
    public subscript(component: Component) -> Int {
        get {
            return components[component] ?? 0
        }
        set {
            components[component] = (newValue == 0 ? nil : newValue)
        }
    }
}

extension PGInterval: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral pairs: (Component, Int)...) {
        self.init()
        for pair in pairs {
            components[pair.0] = pair.1
        }
    }
}

private let correspondences: [(PGInterval.Component, [Calendar.Component])] = [
    (.year, [.year]),
    (.month, [.month]),
    (.week, [.weekOfMonth, .weekOfYear]),
    (.day, [.day]),
    (.hour, [.hour]),
    (.minute, [.minute]),
    (.second, [.second])
]

extension PGInterval {
    /// Creates a `PGInterval` equivalent to the period of time described by 
    /// `dateComponents`. `dateComponents` should describe the difference between 
    /// two dates, not the components of a particular date.
    /// 
    /// - SeeAlso: `Calendar.dateComponents(_:from:to:)`
    public init(_ dateComponents: DateComponents) {
        self.init()
        
        for (int, cals) in correspondences {
            self[int] = cals.compactMap({ dateComponents.value(for: $0) }).first ?? 0
        }
    }
}

public extension DateComponents {
    /// Creates a `DateComponents` describing the same period of time as the 
    /// given `interval`.
    init(_ interval: PGInterval) {
        self.init()
        for (int, cals) in correspondences {
            setValue(interval[int], for: cals.first!)
        }
    }
}
