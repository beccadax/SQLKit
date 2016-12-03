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
        return try Parser().parse(text)
    }
    
    fileprivate struct Parser: StringParser {
        enum ParseState: PGConversionErrorParsingState {
            case start(for: PGInterval)
            case expectingQuantity(in: PGInterval.Component.Section, for: PGInterval)
            case readingQuantity(NumberAccumulator, in: PGInterval.Component.Section, for: PGInterval)
            
            var localizedStateDescription: String {
                switch self {
                case .start:
                    return NSLocalizedString("at the start of the text", comment: "")
                case .expectingQuantity(in: .date, for: _):
                    return NSLocalizedString("while processing the date section", comment: "")
                case .expectingQuantity(in: .time, for: _):
                    return NSLocalizedString("while processing the time section", comment: "")
                case .readingQuantity(_, in: .date, for: _):
                    return NSLocalizedString("while reading a number in the date section", comment: "")
                case .readingQuantity(_, in: .time, for: _):
                    return NSLocalizedString("while reading a number in the time section", comment: "")
                }
            }
        }
        
        let initialParseState = ParseState.start(for: PGInterval())
        
        func continueParsing(_ char: Character, in state: ParseState) throws -> ParseState {
            switch (state, char) {
            case (.start(for: let interval), "P"):
                return .expectingQuantity(in: .date, for: interval)
            
            case (.start, _):
                throw PGConversionError.unexpectedCharacter(char)
                
            case (.expectingQuantity(in: .date, for: let interval), "T"):
                return .expectingQuantity(in: .time, for: interval)
            
            case (.expectingQuantity(in: let section, for: let interval), NumberAccumulator.digits):
                var accumulator = NumberAccumulator()
                accumulator.addDigit(char)
                return .readingQuantity(accumulator, in: section, for: interval)
                
            case (.expectingQuantity, _):
                throw PGConversionError.unexpectedCharacter(char)
            
            case (.readingQuantity(var accumulator, in: let section, for: let interval), NumberAccumulator.digits):
                accumulator.addDigit(char)
                return .readingQuantity(accumulator, in: section, for: interval)
                
            case (.readingQuantity(var accumulator, in: let section, for: var interval), _):
                guard let component = PGInterval.Component(section: section, unit: char) else {
                    throw PGConversionError.unexpectedCharacter(char)
                }
                let newValue = try accumulator.make() as Int
                
                if let oldValue = interval[component] {
                    throw PGConversionError.redundantQuantity(oldValue: oldValue, newValue: newValue, for: component)
                }
                
                interval[component] = newValue
                
                return .expectingQuantity(in: section, for: interval)
            }
        }
        
        func finishParsing(in state: ParseState) throws -> PGInterval {
            switch state {
            case .expectingQuantity(in: _, for: let interval):
                return interval
                
            case .start:
                throw PGConversionError.earlyTermination
                
            case .readingQuantity(var accumulator, in: _, for: _):
                throw PGConversionError.unitlessQuantity(try accumulator.make())
            }
        }
        
        func wrapError(_ error: Error, at index: String.Index, in string: String, during state: ParseState) -> Error {
            return PGConversionError.invalidInterval(error, at: index, in: string, during: state)
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
    
    init?(section: Section, unit: Character) {
        switch (section, unit) {
        case (.date, "Y"): self = .year
        case (.date, "M"): self = .month
        case (.date, "W"): self = .week
        case (.date, "D"): self = .day
        case (.time, "H"): self = .hour
        case (.time, "M"): self = .minute
        case (.time, "S"): self = .second
        default:
            return nil
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
