import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:little_artist/models/database.dart';

/// Handles local notification scheduling for artwork reminders and memories.
///
/// Provides two notification types:
/// - **Inactivity reminder** -- fires 14 days after the most recent artwork.
/// - **On This Day** -- fires at 9 AM each day for artworks created on the
///   same month and day in a previous year.
abstract final class NotificationService {
  // Identifiers
  static const _inactivityId = 0;
  static const _onThisDayIdBase = 1000;

  /// Number of days of inactivity before sending a reminder.
  static const _inactivityDays = 14;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialises the notifications plugin and timezone data.
  ///
  /// Safe to call multiple times; only runs once.
  static Future<void> _ensureInitialised() async {
    if (_initialised) return;

    tz.initializeTimeZones();
    final localName = tz.local.name;
    tz.setLocalLocation(tz.getLocation(localName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialised = true;
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  /// Requests notification authorization from the user.
  ///
  /// Returns `true` if the user granted permission.
  static Future<bool> requestPermission() async {
    await _ensureInitialised();

    // iOS
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Schedule all
  // ---------------------------------------------------------------------------

  /// Cancels existing notifications and schedules new ones based on the
  /// provided artworks.
  static Future<void> scheduleAll(List<Artwork> artworks) async {
    await _ensureInitialised();
    await cancelAll();

    // Inactivity reminder based on the most recent artwork date
    DateTime? mostRecentDate;
    for (final artwork in artworks) {
      if (mostRecentDate == null ||
          artwork.createdAt.isAfter(mostRecentDate)) {
        mostRecentDate = artwork.createdAt;
      }
    }
    await scheduleInactivityReminder(mostRecentDate ?? DateTime.now());

    // On This Day memories
    await scheduleOnThisDayNotifications(artworks);
  }

  // ---------------------------------------------------------------------------
  // Cancel all
  // ---------------------------------------------------------------------------

  /// Removes all pending notification requests scheduled by this service.
  static Future<void> cancelAll() async {
    await _ensureInitialised();
    await _plugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Inactivity reminder
  // ---------------------------------------------------------------------------

  /// Schedules a notification that fires [_inactivityDays] days after
  /// [lastArtworkDate].
  ///
  /// If the trigger date is already in the past, the notification fires
  /// in 1 minute.
  static Future<void> scheduleInactivityReminder(
    DateTime lastArtworkDate,
  ) async {
    await _ensureInitialised();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Artwork capture reminders',
        importance: Importance.high,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final triggerDate = lastArtworkDate.add(
      const Duration(days: _inactivityDays),
    );
    final now = DateTime.now();

    if (triggerDate.isAfter(now)) {
      final scheduledDate = tz.TZDateTime.from(triggerDate, tz.local);
      await _plugin.zonedSchedule(
        _inactivityId,
        'Time to Create!',
        "You haven't captured any artwork recently! Time to add some new creations.",
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // Already overdue -- fire in 60 seconds
      final soon = tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 60),
      );
      await _plugin.zonedSchedule(
        _inactivityId,
        'Time to Create!',
        "You haven't captured any artwork recently! Time to add some new creations.",
        soon,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // On This Day
  // ---------------------------------------------------------------------------

  /// Schedules a daily 9 AM notification for each artwork whose creation
  /// date shares the current month and day in a previous year.
  static Future<void> scheduleOnThisDayNotifications(
    List<Artwork> artworks,
  ) async {
    await _ensureInitialised();

    final now = DateTime.now();
    final todayMonth = now.month;
    final todayDay = now.day;
    int notificationId = _onThisDayIdBase;

    for (final artwork in artworks) {
      final createdAt = artwork.createdAt;
      if (createdAt.month != todayMonth || createdAt.day != todayDay) continue;

      final yearsAgo = now.year - createdAt.year;
      if (yearsAgo < 1) continue;

      final yearLabel = yearsAgo == 1 ? '1 year' : '$yearsAgo years';
      final artworkTitle =
          artwork.title.isEmpty ? 'an artwork' : "'${artwork.title}'";

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          channelDescription: 'Artwork capture reminders',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      // Schedule for 9 AM today
      final scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9,
        0,
      );

      // Only schedule if 9 AM hasn't passed yet
      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        try {
          await _plugin.zonedSchedule(
            notificationId,
            'On This Day',
            'On this day $yearLabel ago, your little artist created $artworkTitle!',
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          debugPrint('Failed to schedule On This Day notification: $e');
        }
      }

      notificationId++;
    }
  }
}
