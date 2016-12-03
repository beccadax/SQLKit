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
    enum Progress: Hashable {
        case year, month, day, hour, minute, second, timeZone, eraB, eraC, end
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
                
        var timestamp = PGTimestamp.timestamp(era: .ad, year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, timeZone: nil)
        var accumulator = NumberAccumulator()
        var expecting = includeDate ? Progress.year : Progress.hour 
        
        for i in text.characters.indices {
            do {
                let char = text.characters[i]
                
                switch (expecting, char) {
                case (AnyOf(.year, .month, .day, .hour, .minute, .second, .timeZone), NumberAccumulator.digits),
                      (.second, ".") where includeDate:
                    accumulator.addDigit(char)
                    
                case (.year, "-") where includeDate:
                    timestamp.date.setYear(to: try accumulator.make())
                    expecting = .month
                    
                case (.month, "-") where includeDate:
                    timestamp.date.setMonth(to: try accumulator.make())
                    expecting = .day
                
                case (.day, " ") where includeDate:
                    timestamp.date.setDay(to: try accumulator.make())
                    if includeTime {
                        expecting = .hour
                    }
                    else {
                        expecting = .eraB
                    }
                    
                case (.hour, ":") where includeTime:
                    timestamp.time?.hour = try accumulator.make()
                    expecting = .minute
                    
                case (.minute, ":") where includeTime:
                    timestamp.time?.minute = try accumulator.make()
                    expecting = .second
                    
                case (.second, AnyOf("+", "-")) where includeTime:
                    timestamp.time?.second = try accumulator.make()
                    accumulator.addDigit(char)
                    expecting = .timeZone
                    
                case (.timeZone, ":") where includeTime:
                    // Ignore this
                    break
                
                case (.second, " ") where includeTime:
                    timestamp.time?.second = try accumulator.make()
                    if includeDate {
                        expecting = .eraB
                    }
                    else {
                        expecting = .end
                    }
                    
                case (.timeZone, " ") where includeTime:
                    timestamp.time?.timeZone = try accumulator.make()
                    if includeDate {
                        expecting = .eraB
                    }
                    else {
                        expecting = .end
                    }
                
                case (.eraB, "B") where includeDate:
                    expecting = .eraC
                
                case (.eraC, "C") where includeDate:
                    timestamp.date.setEra(to: .bc)
                    expecting = .end
                    
                default:
                    throw PGConversionError.unexpectedDateCharacter(char, during: expecting)
                }
            }
            catch {
                throw PGConversionError.invalidDate(underlying: error, at: i, in: text)
            }
        }
        
        do {
            switch expecting {
            case .day where !includeTime:
                timestamp.date.setDay(to: try accumulator.make())
                expecting = .end
            case .second where includeTime:
                timestamp.time?.second = try accumulator.make()
                expecting = .end
            case .timeZone where includeTime:
                timestamp.time?.timeZone = try accumulator.make()
            case .end:
                break
            default:
                throw PGConversionError.earlyTermination(during: expecting)
            }
            
            return timestamp
        }
        catch {
            throw PGConversionError.invalidDate(underlying: error, at: text.characters.endIndex, in: text)
        }
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
            return timestamp.time.map(string(from:))
        }
        
        switch timestamp.date {
        case .distantPast:
            return "-infinity"
            
        case .distantFuture:
            return "infinity"
            
        case let .date(era, year, month, day):
            let timePart = includeTime ? " " + string(from: timestamp.time!) : ""
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
