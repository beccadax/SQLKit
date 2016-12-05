//
//  PGInterval.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/1/16.
//
//

import Foundation

public struct PGInterval {
    public enum Component: Hashable {
        static let all: [Component] = [ .year, .month, .week, .day, .hour, .minute, .second ]
        case year, month, week, day, hour, minute, second
    }
    
    fileprivate var components: [Component: Int] = [:]
    
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
    public init(_ dateComponents: DateComponents) {
        self.init()
        
        for (int, cals) in correspondences {
            self[int] = cals.flatMap({ dateComponents.value(for: $0) }).first ?? 0
        }
    }
}

public extension DateComponents {
    public init(_ interval: PGInterval) {
        self.init()
        for (int, cals) in correspondences {
            setValue(interval[int], for: cals.first!)
        }
    }
}
