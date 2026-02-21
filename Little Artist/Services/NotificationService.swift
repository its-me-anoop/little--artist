//
//  NotificationService.swift
//  Little Artist
//
//  Schedules local notifications for inactivity reminders
//  and "On This Day" artwork memories.
//

import UserNotifications
import SwiftData

/// Handles local notification scheduling for artwork reminders and memories.
///
/// Provides two notification types:
/// - **Inactivity reminder** — fires 14 days after the most recent artwork capture.
/// - **On This Day** — fires at 9 AM each day for artworks created on the same
///   month and day in a previous year.
enum NotificationService {

    // MARK: - Identifiers

    private static let inactivityIdentifier = "com.littleartist.inactivityReminder"
    private static let onThisDayPrefix = "com.littleartist.onThisDay."
    private static let sharedChangePrefix = "com.littleartist.sharedChange."

    /// Number of days of inactivity before sending a reminder.
    private static let inactivityDays: Int = 14

    // MARK: - Permission

    /// Requests notification authorization from the user.
    ///
    /// - Returns: `true` if the user granted permission.
    @discardableResult
    static func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule All

    /// Cancels existing notifications and schedules new ones based on the
    /// provided artworks.
    ///
    /// - Parameter artworks: All artworks currently stored in the app.
    static func scheduleAll(artworks: [Artwork]) {
        cancelAll()

        // Inactivity reminder based on the most recent artwork date
        let mostRecentDate = artworks.map(\.createdAt).max()
        scheduleInactivityReminder(lastArtworkDate: mostRecentDate ?? Date.now)

        // On This Day memories
        scheduleOnThisDayNotifications(artworks: artworks)
    }

    // MARK: - Cancel All

    /// Removes all pending notification requests scheduled by this service.
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Inactivity Reminder

    /// Schedules a notification that fires 14 days after `lastArtworkDate`.
    ///
    /// If the trigger date is already in the past (i.e., it has been more than
    /// 14 days since the last artwork), the notification fires in 1 minute.
    ///
    /// - Parameter lastArtworkDate: The `createdAt` date of the most recent artwork.
    static func scheduleInactivityReminder(lastArtworkDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Create!"
        content.body = "You haven't captured any artwork recently! Time to add some new creations."
        content.sound = .default

        let triggerDate = Calendar.current.date(
            byAdding: .day,
            value: inactivityDays,
            to: lastArtworkDate
        ) ?? lastArtworkDate

        let trigger: UNNotificationTrigger

        if triggerDate > Date.now {
            let interval = triggerDate.timeIntervalSince(Date.now)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        } else {
            // Already overdue — fire in 60 seconds
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: inactivityIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - On This Day

    /// Schedules a daily 9 AM notification for each artwork whose creation
    /// date shares the current month and day in a previous year.
    ///
    /// - Parameter artworks: All artworks to evaluate for matching dates.
    static func scheduleOnThisDayNotifications(artworks: [Artwork]) {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: Date.now)
        guard let todayMonth = today.month, let todayDay = today.day else { return }

        for artwork in artworks {
            let components = calendar.dateComponents([.year, .month, .day], from: artwork.createdAt)
            guard
                components.month == todayMonth,
                components.day == todayDay,
                let artworkYear = components.year
            else { continue }

            let yearsAgo = calendar.component(.year, from: Date.now) - artworkYear
            guard yearsAgo >= 1 else { continue }

            let childName = artwork.child?.name ?? "Your little artist"
            let artworkTitle = artwork.title.isEmpty ? "an artwork" : "'\(artwork.title)'"
            let yearLabel = yearsAgo == 1 ? "1 year" : "\(yearsAgo) years"

            let content = UNMutableNotificationContent()
            content.title = "On This Day"
            content.body = "On this day \(yearLabel) ago, \(childName) created \(artworkTitle)!"
            content.sound = .default

            // Schedule for 9 AM today
            var triggerComponents = DateComponents()
            triggerComponents.hour = 9
            triggerComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerComponents,
                repeats: false
            )

            let identifier = "\(onThisDayPrefix)\(artwork.persistentModelID.hashValue)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Shared Artwork Changes

    /// Sends a local notification when shared artworks are added or updated
    /// by another user.
    ///
    /// Uses a 3-second delay to batch rapid successive syncs. The identifier
    /// is based on the child name hash so successive notifications for the
    /// same child replace (not stack) each other.
    ///
    /// - Parameters:
    ///   - childName: The name of the shared child profile.
    ///   - insertedCount: Number of newly added artworks.
    ///   - updatedCount: Number of updated artworks.
    static func notifySharedArtworkChanges(childName: String, insertedCount: Int, updatedCount: Int) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        guard insertedCount > 0 || updatedCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if insertedCount > 0 && updatedCount == 0 {
            let artworkWord = insertedCount == 1 ? "artwork" : "artworks"
            content.title = "New Artwork for \(childName)"
            content.body = "\(insertedCount) new \(artworkWord) added to \(childName)'s gallery."
        } else if updatedCount > 0 && insertedCount == 0 {
            content.title = "\(childName)'s Gallery Updated"
            content.body = "\(updatedCount) \(updatedCount == 1 ? "artwork" : "artworks") updated."
        } else {
            content.title = "\(childName)'s Gallery Updated"
            content.body = "\(insertedCount) new, \(updatedCount) updated."
        }

        // 3-second delay batches rapid changes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

        // Use child name hash so successive syncs replace, not stack
        let identifier = "\(sharedChangePrefix)\(childName.hashValue)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
