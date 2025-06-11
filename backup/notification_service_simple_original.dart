import 'package:flutter/foundation.dart';

/// A simplified notification service that avoids errors
/// when the FlutterLocalNotifications plugin is not correctly initialized
class NotificationService {
  /// Initialize the notification service
  Future<void> initialize() async {
    // Simple debug log instead of actual initialization
    debugPrint('NotificationService: Simple initialization (disabled)');
  }

  /// Request permissions for notifications
  Future<bool> requestPermissions() async {
    // Always return true for this simplified version
    debugPrint('NotificationService: Permissions requested (auto-granted)');
    return true;
  }

  /// Setup a weekly reminder
  Future<void> setupWeeklyReminder({required bool enabled}) async {
    // Just log the request instead of actual scheduling
    debugPrint('NotificationService: Weekly reminder ${enabled ? 'enabled' : 'disabled'} (simulated)');
  }

  /// Cancel a weekly reminder
  Future<void> cancelWeeklyReminder() async {
    // Just log the request instead of actual cancellation
    debugPrint('NotificationService: Weekly reminder cancelled (simulated)');
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Just log the request instead of actual scheduling
    debugPrint('NotificationService: Notification scheduled for $scheduledDate (simulated)');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Body: $body');
  }
}