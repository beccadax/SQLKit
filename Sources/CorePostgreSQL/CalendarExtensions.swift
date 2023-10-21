//
//  CalendarExtensions.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/1/16.
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

extension Locale {
    internal static let posix = Locale(identifier: "en_US_POSIX")
}
