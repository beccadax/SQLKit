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
        do {
            return try Parser().parse(text)
        }
        catch let StringParserError.parseError(error, at: index, in: string, during: state) {
            throw PGConversionError.invalidInterval(error, at: index, in: string, during: state)
        }
    }
    
    fileprivate struct Parser: StringParser {
        enum ParseState: PGConversionErrorParsingState {
            case start(for: PGInterval)
            case expectingQuantity(in: PGInterval.Component.Section, for: PGInterval)
            case readingQuantity(NumberAccumulator, in: PGInterval.Component.Section, for: PGInterval)
        }
        
        fileprivate let initialParseState = ParseState.start(for: PGInterval())
        
        fileprivate func continueParsing(_ char: Character, in state: ParseState) throws -> ParseState {
            switch (state, char) {
            case (.start(for: let interval), "P"):
                return .expectingQuantity(in: .date, for: interval)
            
            case (.start, _):
                throw PGConversionError.missingIntervalPrefix(char)
                
            case (.expectingQuantity(in: .date, for: let interval), "T"):
                return .expectingQuantity(in: .time, for: interval)
            
            case (.expectingQuantity(in: let section, for: let interval), NumberAccumulator.digits):
                var accumulator = NumberAccumulator()
                accumulator.addDigit(char)
                return .readingQuantity(accumulator, in: section, for: interval)
                
            case (.expectingQuantity, _):
                throw PGConversionError.missingQuantity(char)
            
            case (.readingQuantity(var accumulator, in: let section, for: let interval), NumberAccumulator.digits):
                accumulator.addDigit(char)
                return .readingQuantity(accumulator, in: section, for: interval)
                
            case (.readingQuantity(var accumulator, in: let section, for: var interval), _):
                let component = try PGInterval.Component(section: section, unit: char)
                let newValue = try accumulator.make() as Int
                
                if let oldValue = interval[component] {
                    throw PGConversionError.redundantQuantity(oldValue: oldValue, newValue: newValue, for: component)
                }
                
                interval[component] = newValue
                
                return .expectingQuantity(in: section, for: interval)
            }
        }
        
        fileprivate func finishParsing(in state: ParseState) throws -> PGInterval {
            switch state {
            case .expectingQuantity(in: _, for: let interval):
                return interval
                
            case .start:
                throw PGConversionError.missingIntervalPrefix(nil)
                
            case .readingQuantity(var accumulator, in: _, for: _):
                throw PGConversionError.unitlessQuantity(try accumulator.make())
            }
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
