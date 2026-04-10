//
//  ArtworkDate.swift
//  Little Artist
//
//  Date helpers used across the artwork create/edit flows and the gallery
//  grouping. All artwork dates are anchored to noon local time for the
//  chosen day so that small timezone drifts cannot shift an artwork to the
//  previous or next calendar day.
//

import Foundation

/// Shared helpers for normalising and bucketing artwork dates.
///
/// Every artwork stores a `createdAt` date that is "day-anchored" — set to
/// noon local time for the chosen day. This guarantees:
/// - Edits that preserve the day don't accidentally shift the artwork to a
///   different day because of time-of-day drift.
/// - Grouping by day uses a stable key (``dayKey(for:calendar:)``) regardless
///   of the exact time an artwork was captured.
enum ArtworkDate {

    /// Returns `date` anchored to noon (12:00) on the same calendar day,
    /// optionally offset by a number of seconds (useful for batch imports to
    /// avoid collisions when multiple artworks share a day).
    ///
    /// - Parameters:
    ///   - date: The source date (typically picked by the user).
    ///   - offsetSeconds: Optional seconds offset added after anchoring.
    ///     Defaults to `0`.
    ///   - calendar: Calendar used to derive the day. Defaults to `.current`.
    static func dayAnchored(
        _ date: Date,
        offsetSeconds: Double = 0,
        calendar: Calendar = .current
    ) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        let anchored = calendar.date(from: components) ?? date
        guard offsetSeconds != 0 else { return anchored }
        return anchored.addingTimeInterval(offsetSeconds)
    }

    /// Returns a stable per-day grouping key (start of day) for `date`.
    ///
    /// Used by the gallery to bucket artworks into day sections.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
}
