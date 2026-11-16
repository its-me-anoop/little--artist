//
//  Date+CardLabel.swift
//  Little Artist
//
//  Short date shown on artwork cards. Dates from earlier years carry the
//  year so older art never looks recent.
//

import Foundation

extension Date {

    /// "15 Nov" for dates in the current year, "15 Nov 2025" otherwise
    /// (ordering follows the locale).
    nonisolated func cardLabel(
        relativeTo now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .month(.abbreviated)
            .day()
        if calendar.component(.year, from: self) != calendar.component(.year, from: now) {
            style = style.year()
        }
        return formatted(style)
    }
}
