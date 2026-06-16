import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../../../routes/app_router.dart';
import '../domain/models/medicine_reminder_model.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.actionId == 'MARK_TAKEN') {
    final payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      final parts = payload.split('|');
      final reminderId = parts[0];
      final timeIndex = int.parse(parts[1]);
      final scheduledDateStr = parts[2];
      final timeStr = parts[3];
      final scheduledDate = DateTime.parse(scheduledDateStr);
      final medicineName = parts[4];
      final dosage = parts[5];

      SharedPreferences.getInstance().then((prefs) async {
        final dateStr = "${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}";
        final key = 'med_taken_${reminderId}_${dateStr}_$timeStr';
        await prefs.setBool(key, true);

        final notificationsPlugin = FlutterLocalNotificationsPlugin();
        final baseVal = reminderId.hashCode.abs() % 20000;
        final epochDay = scheduledDate.difference(DateTime(2026, 1, 1)).inDays;
        final dayCode = epochDay % 30;
        final slotBase = baseVal * 400 + timeIndex * 30 + dayCode;

        await notificationsPlugin.cancel(slotBase); // primary notification
        await notificationsPlugin.cancel(slotBase + 2000000); // escalation
        await notificationsPlugin.cancel(slotBase + 4000000); // missed
        await notificationsPlugin.cancel(slotBase + 6000000); // snooze

        final userId = prefs.getString('current_user_uid');
        if (userId != null && userId.isNotEmpty) {
          try {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          } catch (_) {}

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .add({
            'title': '💊 Medicine Taken',
            'message': 'You have marked $medicineName ($dosage) as taken.',
            'type': 'medication',
            'isRead': true,
            'createdAt': DateTime.now().toIso8601String(),
          });
          // Navigate to Reminder Center to reflect changes immediately
          AppRouter.router.push('/reminder-center');
        }
      });
    }
  } else if (notificationResponse.actionId == 'SNOOZE') {
    final payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      final parts = payload.split('|');
      final reminderId = parts[0];
      final timeIndex = int.parse(parts[1]);
      final scheduledDateStr = parts[2];
      final scheduledDate = DateTime.parse(scheduledDateStr);
      final medicineName = parts[4];
      final dosage = parts[5];

      SharedPreferences.getInstance().then((prefs) async {
        final notificationsPlugin = FlutterLocalNotificationsPlugin();
        final soundEnabled = prefs.getBool('reminder_sound_enabled') ?? true;
        final vibrationEnabled = prefs.getBool('reminder_vibration_enabled') ?? true;

        final baseVal = reminderId.hashCode.abs() % 20000;
        final epochDay = scheduledDate.difference(DateTime(2026, 1, 1)).inDays;
        final dayCode = epochDay % 30;
        final slotBase = baseVal * 400 + timeIndex * 30 + dayCode;

        final androidDetails = AndroidNotificationDetails(
          'medicine_reminder_channel_v2',
          'Medicine Reminders',
          channelDescription: 'Scheduled medicine reminder alerts.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000]) : null,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.reminder,
          actions: const [
            AndroidNotificationAction('MARK_TAKEN', 'Mark as Read'),
            AndroidNotificationAction('SNOOZE', 'Snooze 10 Minutes'),
          ],
        );

        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
          categoryIdentifier: 'medicine_reminder',
        );

        tz.initializeTimeZones();
        final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

        await notificationsPlugin.zonedSchedule(
          slotBase + 6000000,
          '💊 Time to Take Medicine (Snoozed)',
          'Medicine Name: $medicineName\nDosage: $dosage\n\nTime to take your medicine.',
          snoozeTime,
          NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      });
    }
  }
}

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medicine_reminder_channel_v2';
  static const String _channelName = 'Medicine Reminders';
  static const String _channelDescription = 'Scheduled medicine reminder alerts.';

  Future<void> initialize() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      // Fallback if platform exception occurs
      tz.setLocalLocation(tz.local);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      try {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
      } catch (_) {}
    }

    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<NotificationDetails> _getNotificationDetails({
    required bool isMissed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('reminder_sound_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('reminder_vibration_enabled') ?? true;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      vibrationPattern: vibrationEnabled
          ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000])
          : null,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      actions: const [],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
      categoryIdentifier: isMissed ? 'medicine_missed' : 'medicine_reminder',
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> scheduleMedicineReminder({
    required MedicineReminderModel reminder,
    required String profileName,
  }) async {
    if (kIsWeb) return;

    final baseVal = reminder.id.hashCode.abs() % 20000;
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < reminder.times.length; i++) {
      final timeStr = reminder.times[i];
      final timeParts = _parseTimeStr(timeStr);
      if (timeParts == null) continue;

      final now = tz.TZDateTime.now(tz.local);

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          timeParts['hour']!,
          timeParts['minute']!,
        ).add(Duration(days: dayOffset));

        // Skip if scheduled date is in the past
        if (scheduledDate.isBefore(now)) {
          continue;
        }

        // Check if already taken
        final dateStr = "${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}";
        final takenKey = 'med_taken_${reminder.id}_${dateStr}_$timeStr';
        if (prefs.getBool(takenKey) ?? false) {
          continue;
        }

        final epochDay = scheduledDate.difference(DateTime(2026, 1, 1)).inDays;
        final dayCode = epochDay % 30;
        final slotBase = baseVal * 400 + i * 30 + dayCode;

        // 1. Primary Reminder
        final primaryTime = scheduledDate;
        final primaryDetails = await _getNotificationDetails(isMissed: false);
        final primaryPayload = '${reminder.id}|$i|${primaryTime.toIso8601String()}|$timeStr|${reminder.medicineName}|${reminder.dosage}';

        await _notifications.zonedSchedule(
          slotBase,
          '💊 Time to Take Medicine',
          'Medicine Name: ${reminder.medicineName}\nDosage: ${reminder.dosage}\n\nTime to take your medicine.',
          primaryTime,
          primaryDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: primaryPayload,
        );

        // 2. 15-minute Escalation
        final escalationTime = scheduledDate.add(const Duration(minutes: 15));
        if (escalationTime.isAfter(now)) {
          final escalationDetails = await _getNotificationDetails(isMissed: false);
          await _notifications.zonedSchedule(
            slotBase + 2000000,
            '💊 Time to Take Medicine',
            'Medicine Name: ${reminder.medicineName}\nDosage: ${reminder.dosage}\n\nTime to take your medicine.',
            escalationTime,
            escalationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: primaryPayload,
          );
        }

        // Missed reminders disabled
      }
    }
  }

  Future<void> cancelReminder(MedicineReminderModel reminder) async {
    if (kIsWeb) return;
    final baseVal = reminder.id.hashCode.abs() % 20000;

    for (int i = 0; i < reminder.times.length; i++) {
      for (int dayCode = 0; dayCode < 30; dayCode++) {
        final slotBase = baseVal * 400 + i * 30 + dayCode;
        await _notifications.cancel(slotBase);
        await _notifications.cancel(slotBase + 2000000);
        await _notifications.cancel(slotBase + 4000000);
        await _notifications.cancel(slotBase + 6000000);
      }
    }
  }

  Future<void> cancelEscalations(String reminderId, int timeIndex, DateTime date) async {
    if (kIsWeb) return;
    final baseVal = reminderId.hashCode.abs() % 20000;
    final epochDay = date.difference(DateTime(2026, 1, 1)).inDays;
    final dayCode = epochDay % 30;
    final slotBase = baseVal * 400 + timeIndex * 30 + dayCode;

    await _notifications.cancel(slotBase); // primary notification
    await _notifications.cancel(slotBase + 2000000); // escalation
    await _notifications.cancel(slotBase + 4000000); // missed
    await _notifications.cancel(slotBase + 6000000); // snooze
  }

  Future<void> logNotificationToFirestore({
    required String title,
    required String message,
    required String type,
    required DateTime createdAt,
    bool isRead = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_uid');
    if (userId == null || userId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'MARK_TAKEN') {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final parts = payload.split('|');
        final reminderId = parts[0];
        final timeIndex = int.parse(parts[1]);
        final scheduledDateStr = parts[2];
        final timeStr = parts[3];
        final scheduledDate = DateTime.parse(scheduledDateStr);
        final medicineName = parts[4];
        final dosage = parts[5];

        SharedPreferences.getInstance().then((prefs) async {
          final dateStr = "${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}";
          final key = 'med_taken_${reminderId}_${dateStr}_$timeStr';
          await prefs.setBool(key, true);

          final baseVal = reminderId.hashCode.abs() % 20000;
          final epochDay = scheduledDate.difference(DateTime(2026, 1, 1)).inDays;
          final dayCode = epochDay % 30;
          final slotBase = baseVal * 400 + timeIndex * 30 + dayCode;

          await _notifications.cancel(slotBase + 2000000); // escalation
          await _notifications.cancel(slotBase + 4000000); // missed
          await _notifications.cancel(slotBase + 6000000); // snooze

          final userId = prefs.getString('current_user_uid');
          if (userId != null && userId.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .add({
              'title': '💊 Medicine Taken',
              'message': 'You have marked $medicineName ($dosage) as taken.',
              'type': 'medication',
              'isRead': true,
              'createdAt': DateTime.now().toIso8601String(),
            });
            // Optionally, you could also trigger a local state update via shared prefs
            // UI will reflect via MedicineTakenStatusNotifier reading SharedPreferences.
          }
        });
      }
    } else if (response.actionId == 'SNOOZE') {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final parts = payload.split('|');
        final reminderId = parts[0];
        final timeIndex = int.parse(parts[1]);
        final scheduledDateStr = parts[2];
        final scheduledDate = DateTime.parse(scheduledDateStr);
        final medicineName = parts[4];
        final dosage = parts[5];

        SharedPreferences.getInstance().then((prefs) async {
          final soundEnabled = prefs.getBool('reminder_sound_enabled') ?? true;
          final vibrationEnabled = prefs.getBool('reminder_vibration_enabled') ?? true;

          final baseVal = reminderId.hashCode.abs() % 20000;
          final epochDay = scheduledDate.difference(DateTime(2026, 1, 1)).inDays;
          final dayCode = epochDay % 30;
          final slotBase = baseVal * 400 + timeIndex * 30 + dayCode;

          final androidDetails = AndroidNotificationDetails(
            'medicine_reminder_channel_v2',
            'Medicine Reminders',
            channelDescription: 'Scheduled medicine reminder alerts.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: soundEnabled,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000]) : null,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.reminder,
            actions: const [],
          );

          final iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: soundEnabled,
            categoryIdentifier: 'medicine_reminder',
          );

          final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

          await _notifications.zonedSchedule(
            slotBase + 6000000,
            '💊 Time to Take Medicine (Snoozed)',
            'Medicine Name: $medicineName\nDosage: $dosage\n\nTime to take your medicine.',
            snoozeTime,
            NotificationDetails(android: androidDetails, iOS: iosDetails),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
          // Cancel the original primary notification to avoid duplicate alerts
          await _notifications.cancel(slotBase);

        });
      }
    } else {
      AppRouter.router.push('/reminder-center');
    }
  }

  Map<String, int>? _parseTimeStr(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (parts[1].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      return {'hour': hour, 'minute': minute};
    } catch (e) {
      return null;
    }
  }
}
