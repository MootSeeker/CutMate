import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cutmate/constants/app_constants.dart';

/// Service for managing local notifications in the app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  /// Initialize notification settings
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  /// Request notification permissions
  Future<void> requestPermissions() async {
    // Request permission for iOS
    final bool? granted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    // Request permission for Android 13 and above
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestPermission();
  }
  
  /// Check if weekly reminder should be enabled and set it up
  Future<void> setupWeeklyReminder({required bool enabled}) async {
    // Cancel any existing reminders first
    await cancelWeeklyReminder();
    
    if (enabled) {
      // Schedule new weekly reminder
      await scheduleWeeklyReminder();
    }
  }
  
  /// Schedule weekly weight log reminder
  Future<void> scheduleWeeklyReminder() async {
    // Schedule for Monday at 9:00 AM
    final tz.TZDateTime scheduledDate = _nextInstanceOf(9, 0, DateTime.monday);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      AppConstants.weeklyReminderNotificationId,
      'Time to log your weight!',
      'Track your weekly progress to stay on target with your goals.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.weeklyReminderChannelId,
          AppConstants.weeklyReminderChannelName,
          channelDescription: AppConstants.weeklyReminderChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
  
  /// Cancel weekly reminder
  Future<void> cancelWeeklyReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(AppConstants.weeklyReminderNotificationId);
  }
  
  /// Get next date instance for the notification
  tz.TZDateTime _nextInstanceOf(int hour, int minute, int dayOfWeek) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse details) {
    // Handle notification tap - can implement navigation to weight entry screen
  }
}
