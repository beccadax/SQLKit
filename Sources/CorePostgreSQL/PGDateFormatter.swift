//
//  PGDateFormatter.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/1/16.
//
//

import Foundation

class PGDateFormatter: Formatter {
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
        return try dateComponents(from: string)
    }
    
    override func string(for objectValue: Any?) -> String? {
        return (objectValue as? DateComponents).map(string(from:))
    }
}

extension PGDateFormatter {
    struct ComponentWriter {
        var dateComponents = DateComponents()
        
        var digits = ""
        var currentComponent = Calendar.Component.year
        
        mutating func addDigit(_ digit: Character) {
            digits.append(digit)
        }
        
        mutating func advance(to nextComponent: Calendar.Component) throws {
            try writeDigitsToCurrentComponent()
            digits = ""
            currentComponent = nextComponent
        }
        
        mutating func writeDigitsToCurrentComponent() throws {
            switch currentComponent {
            case .timeZone:
                let hours: Int
                let minutes: Int
                
                switch digits.characters.count {
                case 2, 3:
                    hours = try Int(textualRawPGValue: digits)
                    minutes = 0
                case 4, 5:
                    hours = try Int(textualRawPGValue: digits.dropLast(2))
                    minutes = try Int(textualRawPGValue: digits.prefix(1) + digits.suffix(2))
                default:
                    throw PGConversionError.invalidTimeZoneOffset(digits)
                }
                
                let offset = (hours * 60 + minutes) * 60
                dateComponents.timeZone = TimeZone(secondsFromGMT: offset)
                
            case .nanosecond:
                let paddingNeeded = DateComponents.nanosecondDigits - digits.characters.count
                
                if paddingNeeded >= 0 {
                    digits += String(repeating: "0", count: paddingNeeded) 
                }
                else {
                    digits = digits.prefix(-paddingNeeded)
                }
                fallthrough
                
            default:
                dateComponents.setValue(try Int(textualRawPGValue: digits), for: currentComponent)
            }
        }
    }
    
    func dateComponents(from text: String) throws -> DateComponents {
        var writer = ComponentWriter()
        
        for i in text.characters.indices {
            do {
                let char = text.characters[i]
                
                switch (char, writer.currentComponent) {
                case ("0", _), 
                     ("1", _), 
                     ("2", _), 
                     ("3", _), 
                     ("4", _), 
                     ("5", _), 
                     ("6", _), 
                     ("7", _), 
                     ("8", _), 
                     ("9", _):
                    writer.addDigit(char)
                    
                case ("-", .year) where writer.digits.isEmpty:
                    writer.addDigit(char)
                    
                case ("-", .year):
                    try writer.advance(to: .month)
                case ("-", .month):
                    try writer.advance(to: .day)
                    
                case (" ", .year), ("T", .year),
                     (" ", .month), ("T", .month), 
                     (" ", .day), ("T", .day):
                    try writer.advance(to: .hour)
                    
                case (":", .year):
                    // There actually isn't a date here--reinterpret the current 
                    // digits as an hour.
                    writer.currentComponent = .hour
                    fallthrough
                    
                case (":", .hour):
                    try writer.advance(to: .minute)
                case (":", .minute):
                    try writer.advance(to: .second)
                case (".", .second):
                    try writer.advance(to: .nanosecond)
                    
                case ("-", .hour), ("+", .hour), 
                     ("-", .minute), ("+", .minute), 
                     ("-", .second), ("+", .second), 
                     ("-", .nanosecond), ("+", .nanosecond):
                    try writer.advance(to: .timeZone)
                    writer.addDigit(char)
                    
                case (":", .timeZone):
                    // Ignore this
                    break
                    
                default:
                    throw PGConversionError.unexpectedDateCharacter(char, during: writer.currentComponent)
                }
            }
            catch {
                throw PGConversionError.invalidDateComponents(underlying: error, at: i, in: text)
            }
        }
        
        do {
            try writer.writeDigitsToCurrentComponent()
            return writer.dateComponents
        }
        catch {
            throw PGConversionError.invalidDateComponents(underlying: error, at: text.characters.endIndex, in: text)
        }
    }
}

extension PGDateFormatter {
    func string(from comps: DateComponents) -> String {
        func f(_ number: Int?, digits: Int = 2) -> String {
            return (number ?? 0).formatted(digits: digits)
        }
        
        func any(_ values: Int?...) -> Bool {
            for case _? in values {
                return true
            }
            return false
        }
        
        let datePart: String?
        let timeAndZonePart: String?
        
        if any(comps.year, comps.month, comps.day) {
            datePart = "\(f(comps.year))-\(f(comps.month))-\(f(comps.day))"
        }
        else {
            datePart = nil
        }
        
        if any(comps.hour, comps.minute, comps.second, comps.nanosecond) {
            let timePart = "\(f(comps.hour)):\(f(comps.minute)):\(f(comps.second)).\(f(comps.nanosecond, digits: DateComponents.nanosecondDigits))"
            
            let calendar = comps.calendar ?? Calendar(identifier: .gregorian)        
            if let timeZone = comps.timeZone {
                let baseTime = calendar.date(from: comps) ?? Date()
                
                let offset = timeZone.secondsFromGMT(for: baseTime)
                let offsetInMinutes = offset / 60
                
                let minutes = abs(offsetInMinutes) % 60
                let hours = abs(offsetInMinutes) / 60
                
                let sign = offset < 0 ? "-" : "+"
                timeAndZonePart = timePart + sign + f(hours) + f(minutes)
            }
            else {
                timeAndZonePart = timePart
            }
        }
        else {
            timeAndZonePart = nil
        }
        
        return [datePart, timeAndZonePart].flatMap { $0 }.joined(separator: " ")        
    }
}

private extension String {
    func prefix(_ maxLength: Int) -> String {
        return String(characters.prefix(maxLength))
    }
    func suffix(_ maxLength: Int) -> String {
        return String(characters.suffix(maxLength))
    }
    func dropFirst(_ maxLength: Int) -> String {
        return String(characters.dropFirst(maxLength))
    }
    func dropLast(_ maxLength: Int) -> String {
        return String(characters.dropLast(maxLength))
    }
}

extension Int {
    func formatted(digits: Int) -> String {
        let base = String(self)
        
        let extraCount = digits - base.characters.count
        guard extraCount > 0 else {
            return base
        }
        
        let extra = String(repeating: "0", count: extraCount)
        return extra + base
    }
}
