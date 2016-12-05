//
//  PGTimestampFormatter.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/1/16.
//
//

import Foundation

class PGTimestampFormatter: Formatter {
    enum Style {
        case timestamp
        case date
        case time
    }
    
    var style = Style.timestamp
    
    init(style: Style) {
        super.init()
        self.style = style
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        return try timestamp(from: string)
    }
    
    override func string(for objectValue: Any?) -> String? {
        return (objectValue as? PGTimestamp).flatMap(string(from:))
    }
}

extension PGTimestampFormatter {
    fileprivate struct Parser: StringParser {
        let formatter: PGTimestampFormatter
        
        enum NumericField: Hashable {
            case year, month, day, hour, minute, second, timeZone
        }
        
        enum ParseState: PGConversionParsingState {
            case expectingField(NumericField, for: PGTimestamp)
            case parsingField(NumericField, accumulated: ValueAccumulator, for: PGTimestamp)
            case expectingEraB(for: PGTimestamp)
            case expectingEraC(for: PGTimestamp)
            case parsedBC(for: PGTimestamp)
            
            var localizedStateDescription: String {
                switch self {
                case .expectingField(let field, for: _):
                    return NSLocalizedString("instead of the \(field) field", comment: "")
                case .parsingField(let field, accumulated: _, for: _):
                    return NSLocalizedString("while parsing the \(field) field", comment: "")
                case .expectingEraB, .expectingEraC:
                    return NSLocalizedString("instead of the 'BC' suffix", comment: "")
                case .parsedBC:
                    return NSLocalizedString("after the 'BC' suffix", comment: "")
                }
            }
        }
        
        var initialParseState: ParseState {
            if formatter.includeDate {
                return .expectingField(.year, for: PGTimestamp())
            }
            else {
                return .expectingField(.hour, for: PGTimestamp())
            }
        }
        
        func continueParsing(_ char: Character, in state: ParseState) throws -> ParseState {
            switch (state, char) {
            case (let .expectingField(field, for: timestamp), AnyOf.digits):
                return .parsingField(field, accumulated: ValueAccumulator(char), for: timestamp)
            
            case (.parsingField(let field, accumulated: let accumulator, for: let timestamp), AnyOf.digits):
                return .parsingField(field, accumulated: accumulator.adding(char), for: timestamp)
                
            case (.parsingField(.year, accumulated: let accumulator, for: var timestamp), "-"):
                timestamp.date.setYear(to: try accumulator.make())
                return .expectingField(.month, for: timestamp)
                
            case (.parsingField(.month, accumulated: let accumulator, for: var timestamp), "-"):
                timestamp.date.setMonth(to: try accumulator.make())
                return .expectingField(.day, for: timestamp)
                
            case (.parsingField(.day, accumulated: let accumulator, for: var timestamp), " "):
                timestamp.date.setDay(to: try accumulator.make())
                if formatter.includeTime {
                    return .expectingField(.hour, for: timestamp)
                }
                else {
                    return .expectingEraB(for: timestamp)
                }
            
            case (.parsingField(.hour, accumulated: let accumulator, for: var timestamp), ":"):
                timestamp.time.hour = try accumulator.make()
                return .expectingField(.minute, for: timestamp)
                
            case (.parsingField(.minute, accumulated: let accumulator, for: var timestamp), ":"):
                timestamp.time.minute = try accumulator.make()
                return .expectingField(.second, for: timestamp)
                
            case (.parsingField(.second, accumulated: let accumulator, for: let timestamp), "."):
                return .parsingField(.second, accumulated: accumulator.adding(char), for: timestamp)
                
            case (.parsingField(.second, accumulated: let accumulator, for: var timestamp), AnyOf("+", "-")):
                timestamp.time.second = try accumulator.make()
                return .parsingField(.timeZone, accumulated: ValueAccumulator(char), for: timestamp)
            
            case (.parsingField(.second, accumulated: let accumulator, for: var timestamp), " ") where formatter.includeDate:
                timestamp.time.second = try accumulator.make()
                return .expectingEraB(for: timestamp)
                
            case (.parsingField(.timeZone, accumulated: _, for: _), ":"):
                // Ignore this character
                return state
                
            case (.parsingField(.timeZone, accumulated: let accumulator, for: var timestamp), " ") where formatter.includeDate:
                timestamp.time.timeZone = try accumulator.make()
                return .expectingEraB(for: timestamp)
            
            case (.expectingEraB(for: let interval), "B"):
                return .expectingEraC(for: interval)
                
            case (.expectingEraC(for: var interval), "C"):
                interval.date.setEra(to: .bc)
                return .parsedBC(for: interval)
                
            default:
                throw PGError.unexpectedCharacter(char)
            }
        }
        
        func finishParsing(in state: ParseState) throws -> PGTimestamp {
            switch state {
            case .parsingField(.day, accumulated: let accumulator, for: var timestamp) where !formatter.includeTime:
                timestamp.date.setDay(to: try accumulator.make())
                return timestamp
                
            case .parsingField(.second, accumulated: let accumulator, for: var timestamp):
                timestamp.time.second = try accumulator.make()
                return timestamp
                
            case .parsingField(.timeZone, accumulated: let accumulator, for: var timestamp):
                timestamp.time.timeZone = try accumulator.make()
                return timestamp
                
            case .parsedBC(for: let timestamp):
                return timestamp
                
            default:
                throw PGError.earlyTermination
            }
        }
        
        func wrapError(_ error: Error, at index: String.Index, in string: String, during state: ParseState) -> Error {
            switch formatter.style {
            case .timestamp:
                return PGError.invalidTimestamp(error, at: index, in: string, during: state)
            case .date:
                return PGError.invalidDate(error, at: index, in: string, during: state)
            case .time:
                return PGError.invalidTime(error, at: index, in: string, during: state)
            }
        }
    }
    
    var includeTime: Bool { return style != .date }
    var includeDate: Bool { return style != .time }
    
    func timestamp(from text: String) throws -> PGTimestamp {
        if includeDate {
            switch text {
            case "infinity":
                return .distantFuture
            case "-infinity":
                return .distantPast
            default:
                break
            }
        }
        
        return try Parser(formatter: self).parse(text)
    }
}

extension PGTimestampFormatter {
    private func string(from time: PGTime) -> String {
        let baseTime = "\(f(time.hour)):\(f(time.minute)):\(f(time.second))"
        
        guard let timeZone = time.timeZone else {
            return baseTime
        }
        
        let sign = (timeZone.hours < 0) ? "-" : "+"
        let hours = abs(timeZone.hours)
        let minutes = abs(timeZone.minutes)
        
        return baseTime + sign + f(hours) + f(minutes)
    }
    
    func string(from timestamp: PGTimestamp) -> String? {
        if !includeDate {
            return string(from: timestamp.time)
        }
        
        switch timestamp.date {
        case .distantPast:
            return "-infinity"
            
        case .distantFuture:
            return "infinity"
            
        case let .date(era, year, month, day):
            let timePart = includeTime ? " " + string(from: timestamp.time) : ""
            let datePart = "\(f(year, digits: 4))-\(f(month))-\(f(day))"
            
            switch era {
            case .ad:
                return datePart + timePart
            case .bc:
                return datePart + timePart + " BC"
            }
        }
    }
}
