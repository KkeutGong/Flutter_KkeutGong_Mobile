// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Shared key for the milestone payload that the home tab reads on mount
/// to show a confetti banner explaining why the notification fired.
const kPendingMilestoneKey = 'pending_milestone_payload';

/// Scaffold for local push notifications.
///
/// FCM / APNs wiring is intentionally left for a later step.
/// See lib/core/notifications/notifications.md for setup instructions.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _channelId = 'kkeutgong_daily';
  static const _channelName = '일일 학습 알림';
  static const _reminderNotificationId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // Fall back to UTC if Asia/Seoul not found in trimmed tz data.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
    // App launch via notification tap (cold start) — pick up the payload
    // that brought us here so the home tab can render its confetti banner
    // even on the first frame.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final coldPayload = launch?.notificationResponse?.payload;
    if (coldPayload != null && coldPayload.isNotEmpty) {
      await _persistPayload(coldPayload);
    }
  }

  static Future<void> _onTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    await _persistPayload(payload);
  }

  static Future<void> _persistPayload(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPendingMilestoneKey, payload);
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  /// Schedule a daily 9 PM learning reminder.
  Future<void> scheduleDailyReminder() async {
    await cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _reminderNotificationId,
      '📚 오늘 학습하셨나요?',
      '끝공에서 오늘의 학습을 완료해 보세요!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Fire a one-shot milestone notification immediately. Used for
  /// streak / pass-meter / mission-incomplete celebrations triggered
  /// from the home view-model after a /study/today refresh.
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }
}

// ── TODO: FCM / APNs remote push setup ──────────────────────────────────────
// See: lib/core/notifications/notifications.md
