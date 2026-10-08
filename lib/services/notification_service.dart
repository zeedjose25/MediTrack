import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/sample_medications.dart';
import '../models/medication.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const String _prefKey = 'remindersEnabled';

// App-wide switch (the Profile screen toggle controls this).
final ValueNotifier<bool> remindersEnabledNotifier = ValueNotifier<bool>(true);

// ============================================================
// SETUP: call once in main()
// ============================================================

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone));
  } catch (e) {
    debugPrint('Timezone error: $e');
  }

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _plugin.initialize(const InitializationSettings(android: android));

  final prefs = await SharedPreferences.getInstance();
  remindersEnabledNotifier.value = prefs.getBool(_prefKey) ?? true;

  await requestNotificationPermissions();

  // Keep notifications in sync with the medicine list and the switch.
  medicationNotifier.addListener(_resync);
  remindersEnabledNotifier.addListener(_resync);
  _resync();
}

Future<void> requestNotificationPermissions() async {
  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();
}

Future<void> setRemindersEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKey, value);
  remindersEnabledNotifier.value = value;
  if (value) await requestNotificationPermissions();
}

// ============================================================
// SCHEDULING
// ============================================================

void _resync() {
  rescheduleAll(medicationNotifier.value);
}

// Cancels everything and schedules again from the current list.
// Simple and safe: edited or deleted times can never leave old alerts behind.
Future<void> rescheduleAll(List<Medication> meds) async {
  await _plugin.cancelAll();

  if (!remindersEnabledNotifier.value) return;

  for (final med in meds) {
    if (!med.reminderEnabled || isAsNeeded(med.frequency)) continue;

    for (final time in {...med.times}) {
      await _scheduleDaily(med, time);
    }
  }
}

int _idFor(String medicationId, String time) =>
    '${medicationId}_$time'.hashCode & 0x7FFFFFFF;

Future<void> _scheduleDaily(Medication med, String time) async {
  final t = parseTime24(time);
  final now = tz.TZDateTime.now(tz.local);

  var when = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    t.hour,
    t.minute,
  );
  if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

  try {
    await _plugin.zonedSchedule(
      _idFor(med.id, time),
      'Time for ${med.name}',
      '${med.dosage} • ${display12(time)}',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_reminders',
          'Dose reminders',
          channelDescription: 'Reminders to take your medicines',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  } catch (e) {
    debugPrint('Could not schedule ${med.name} at $time: $e');
  }
}

// ============================================================
// TEST BUTTON HELPER (remove later if you like)
// ============================================================

Future<void> showTestNotification() async {
  await _plugin.show(
    999999,
    'MediTrack test',
    'Notifications are working.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'dose_reminders',
        'Dose reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
