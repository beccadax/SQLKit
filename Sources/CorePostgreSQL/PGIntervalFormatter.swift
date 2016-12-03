//
//  PGIntervalFormatter.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/1/16.
//
//

import Foundation

class PGIntervalFormatter: Formatter {
    override func getObjectValue(_ objectValue: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        do {
            let value = try self.objectValue(for: string)
            if let objectValue = objectValue {
                objectValue.pointee = value as AnyObject?
            }
            return true
        }
        catch {
            if let errorDescription = errorDescription {
                errorDescription.pointee = error.localizedDescription as NSString
            }
            return false
        }
    }
    
    func objectValue(for string: String) throws -> Any? {
        return try interval(from: string)
    }
    
    override func string(for objectValue: Any?) -> String? {
        return (objectValue as? PGInterval).map(string(from:))
    }
}

extension PGIntervalFormatter {
    func interval(from text: String) throws -> PGInterval {
        var accumulator = NumberAccumulator()
        var interval = PGInterval()
        var section: PGInterval.Component.Section? = nil
        
        func advance(to newSection: PGInterval.Component.Section?) throws {
            guard accumulator.isEmpty else {
                throw PGConversionError.unitlessQuantity(try accumulator.make())
            }
            section = newSection
        }
        
        for i in text.characters.indices {
            let char = text.characters[i]
            do {
                switch (section, char) {
                case (nil, "P"):
                    // We expect and require a leading "P".
                    try advance(to: .date)
                    
                case (nil, _):
                    throw PGConversionError.missingIntervalPrefix(char)
                
                case (_?, AnyOf("+", "-")) where accumulator.isEmpty,
                      (_?, NumberAccumulator.digits):
                    accumulator.addDigit(char)
                    
                case (.date?, "T"):
                    try advance(to: .time)
                    
                case (let section?, _):
                    let component = try PGInterval.Component(section: section, unit: char)
                    let newValue = try accumulator.make() as Int
                    
                    if let oldValue = interval[component] {
                        throw PGConversionError.redundantQuantity(oldValue: oldValue, newValue: newValue, for: component)
                    }
                    
                    interval[component] = newValue
                }
            }
            catch {
                throw PGConversionError.invalidInterval(underlying: error, at: i, in: text)
            }
        }
        
        do {
            try advance(to: nil)
            return interval
        }
        catch {
            throw PGConversionError.invalidInterval(underlying: error, at: text.characters.endIndex, in: text)
        }
    }
}

extension PGIntervalFormatter {
    func string(from interval: PGInterval) -> String {
        var result = "P"
        
        result += components(from: .date, in: interval)
        
        let times = components(from: .time, in: interval)
        if !times.isEmpty {
            result += "T" + times
        }
        
        return result
    }
    
    fileprivate func components(from section: PGInterval.Component.Section, in interval: PGInterval) -> String {
        return section.components.flatMap { component in
            interval[component].map { value in "\(value)\(component.unit)" }
        }.joined()
    }
}

fileprivate extension PGInterval.Component {
    enum Section {
        static let all: [Section] = [.date, .time]
        
        case date
        case time
        
        var components: [PGInterval.Component] {
            switch self {
            case .date:
                return [.year, .month, .week, .day]
            case .time:
                return [.hour, .minute, .second]
            }
        }
    }
    
    var section: Section {
        switch self {
        case .year, .month, .week, .day:
            return .date
        case .hour, .minute, .second:
            return .time
        }
    }
    
    init(section: Section, unit: Character) throws {
        switch (section, unit) {
        case (.date, "Y"): self = .year
        case (.date, "M"): self = .month
        case (.date, "W"): self = .week
        case (.date, "D"): self = .day
        case (.time, "H"): self = .hour
        case (.time, "M"): self = .minute
        case (.time, "S"): self = .second
        default:
            throw PGConversionError.unknownIntervalUnit(unit)
        }
    }
    
    var unit: String {
        switch self {
        case .year: return "Y"
        case .month: return "M"
        case .week: return "W"
        case .day: return "D"
        case .hour: return "H"
        case .minute: return "M"
        case .second: return "S"
        }
    }
}
