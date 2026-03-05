//
//  GeminiUsageTracker.swift
//  Little Artist
//
//  Tracks and enforces daily, weekly, and monthly usage limits
//  for Gemini API requests to control cloud AI costs.
//

import Foundation
import os

/// Tracks Gemini API request usage and enforces rate limits.
///
/// Persists counters in UserDefaults with automatic period rollover.
/// Each call to `recordRequest()` increments the current period's count.
/// Call `canMakeRequest()` before every Gemini API call to check limits.
@MainActor
@Observable
final class GeminiUsageTracker {

    // MARK: - Singleton

    static let shared = GeminiUsageTracker()

    // MARK: - Limits

    /// Maximum Gemini requests per day.
    static let dailyLimit = 15

    /// Maximum Gemini requests per week.
    static let weeklyLimit = 60

    /// Maximum Gemini requests per month.
    static let monthlyLimit = 200

    // MARK: - State

    /// Current number of requests made today.
    private(set) var dailyCount: Int = 0

    /// Current number of requests made this week.
    private(set) var weeklyCount: Int = 0

    /// Current number of requests made this month.
    private(set) var monthlyCount: Int = 0

    // MARK: - Persistence Keys

    private enum Keys {
        static let dailyCount = "geminiDailyCount"
        static let weeklyCount = "geminiWeeklyCount"
        static let monthlyCount = "geminiMonthlyCount"
        static let lastDailyReset = "geminiLastDailyReset"
        static let lastWeeklyReset = "geminiLastWeeklyReset"
        static let lastMonthlyReset = "geminiLastMonthlyReset"
    }

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "GeminiUsage")

    // MARK: - Init

    private init() {
        rolloverIfNeeded()
    }

    // MARK: - Public API

    /// Whether a new Gemini API request is allowed under all active limits.
    var canMakeRequest: Bool {
        rolloverIfNeeded()
        return dailyCount < Self.dailyLimit
            && weeklyCount < Self.weeklyLimit
            && monthlyCount < Self.monthlyLimit
    }

    /// The most restrictive limit that is currently exceeded, if any.
    var exceededLimit: ExceededLimit? {
        rolloverIfNeeded()
        if dailyCount >= Self.dailyLimit {
            return .daily(resetDate: nextDailyReset)
        }
        if weeklyCount >= Self.weeklyLimit {
            return .weekly(resetDate: nextWeeklyReset)
        }
        if monthlyCount >= Self.monthlyLimit {
            return .monthly(resetDate: nextMonthlyReset)
        }
        return nil
    }

    /// Records a successful Gemini API request.
    func recordRequest() {
        rolloverIfNeeded()
        dailyCount += 1
        weeklyCount += 1
        monthlyCount += 1
        save()
        logger.info("Gemini usage: \(self.dailyCount)/\(Self.dailyLimit) daily, \(self.weeklyCount)/\(Self.weeklyLimit) weekly, \(self.monthlyCount)/\(Self.monthlyLimit) monthly")
    }

    /// Remaining requests for the most restrictive active period.
    var remainingRequests: Int {
        rolloverIfNeeded()
        return min(
            Self.dailyLimit - dailyCount,
            Self.weeklyLimit - weeklyCount,
            Self.monthlyLimit - monthlyCount
        )
    }

    /// Summary of current usage across all periods.
    var usageSummary: UsageSummary {
        rolloverIfNeeded()
        return UsageSummary(
            daily: PeriodUsage(used: dailyCount, limit: Self.dailyLimit, resetDate: nextDailyReset),
            weekly: PeriodUsage(used: weeklyCount, limit: Self.weeklyLimit, resetDate: nextWeeklyReset),
            monthly: PeriodUsage(used: monthlyCount, limit: Self.monthlyLimit, resetDate: nextMonthlyReset)
        )
    }

    // MARK: - Period Rollover

    /// Checks whether any tracking period has elapsed and resets the corresponding counter.
    @discardableResult
    private func rolloverIfNeeded() -> Bool {
        let now = Date()
        var didReset = false

        // Daily reset
        let lastDaily = defaults.object(forKey: Keys.lastDailyReset) as? Date ?? .distantPast
        if !calendar.isDate(lastDaily, inSameDayAs: now) {
            dailyCount = 0
            defaults.set(now, forKey: Keys.lastDailyReset)
            didReset = true
        } else {
            dailyCount = defaults.integer(forKey: Keys.dailyCount)
        }

        // Weekly reset (start of ISO week)
        let lastWeekly = defaults.object(forKey: Keys.lastWeeklyReset) as? Date ?? .distantPast
        let currentWeek = calendar.component(.weekOfYear, from: now)
        let currentWeekYear = calendar.component(.yearForWeekOfYear, from: now)
        let lastWeekNum = calendar.component(.weekOfYear, from: lastWeekly)
        let lastWeekYear = calendar.component(.yearForWeekOfYear, from: lastWeekly)
        if currentWeek != lastWeekNum || currentWeekYear != lastWeekYear {
            weeklyCount = 0
            defaults.set(now, forKey: Keys.lastWeeklyReset)
            didReset = true
        } else {
            weeklyCount = defaults.integer(forKey: Keys.weeklyCount)
        }

        // Monthly reset
        let lastMonthly = defaults.object(forKey: Keys.lastMonthlyReset) as? Date ?? .distantPast
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let lastMonth = calendar.component(.month, from: lastMonthly)
        let lastYear = calendar.component(.year, from: lastMonthly)
        if currentMonth != lastMonth || currentYear != lastYear {
            monthlyCount = 0
            defaults.set(now, forKey: Keys.lastMonthlyReset)
            didReset = true
        } else {
            monthlyCount = defaults.integer(forKey: Keys.monthlyCount)
        }

        if didReset {
            save()
            logger.info("Gemini usage counters reset")
        }

        return didReset
    }

    // MARK: - Persistence

    private func save() {
        defaults.set(dailyCount, forKey: Keys.dailyCount)
        defaults.set(weeklyCount, forKey: Keys.weeklyCount)
        defaults.set(monthlyCount, forKey: Keys.monthlyCount)
    }

    // MARK: - Reset Date Helpers

    private var nextDailyReset: Date {
        calendar.startOfDay(for: Date()).addingTimeInterval(86400)
    }

    private var nextWeeklyReset: Date {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = calendar.firstWeekday
        let startOfWeek = calendar.date(from: components) ?? Date()
        return calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? Date()
    }

    private var nextMonthlyReset: Date {
        let components = calendar.dateComponents([.year, .month], from: Date())
        let startOfMonth = calendar.date(from: components) ?? Date()
        return calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? Date()
    }
}

// MARK: - Supporting Types

/// Describes which usage limit was exceeded and when it resets.
enum ExceededLimit {
    case daily(resetDate: Date)
    case weekly(resetDate: Date)
    case monthly(resetDate: Date)

    var message: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        switch self {
        case .daily(let resetDate):
            return "Daily AI limit reached. Resets \(formatter.localizedString(for: resetDate, relativeTo: Date()))."
        case .weekly(let resetDate):
            return "Weekly AI limit reached. Resets \(formatter.localizedString(for: resetDate, relativeTo: Date()))."
        case .monthly(let resetDate):
            return "Monthly AI limit reached. Resets \(formatter.localizedString(for: resetDate, relativeTo: Date()))."
        }
    }
}

/// Usage data for a single tracking period.
struct PeriodUsage {
    let used: Int
    let limit: Int
    let resetDate: Date

    var remaining: Int { max(0, limit - used) }
    var fraction: Double { Double(used) / Double(limit) }
    var isExceeded: Bool { used >= limit }
}

/// Snapshot of usage across all three periods.
struct UsageSummary {
    let daily: PeriodUsage
    let weekly: PeriodUsage
    let monthly: PeriodUsage
}
