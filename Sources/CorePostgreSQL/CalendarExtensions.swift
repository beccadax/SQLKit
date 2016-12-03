//
//  CalendarExtensions.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/1/16.
//
//

import Foundation

extension Calendar {
    internal static let gregorian = Calendar(identifier: .gregorian)
}

extension TimeZone {
    internal static let utc = TimeZone(secondsFromGMT: 0)!
}

extension DateComponents {
    internal static let nanosecondDigits = 9
}
