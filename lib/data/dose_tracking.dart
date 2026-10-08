import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/medication.dart';
import 'sample_medications.dart';

// ============================================================
// SETTINGS (change these to tune when a dose counts as due/missed)
// ============================================================

// A dose becomes "Due now" this many minutes BEFORE its time...
const int dueBeforeMinutes = 5;

// ...and becomes "Missed" this many minutes AFTER its time.
const int missedAfterMinutes = 60;

// How many days of dose history are loaded from Firestore.
const int historyDays = 14;

// How long after "Mark as Taken" a dose can still be undone.
const int undoWindowMinutes = 3;

// ============================================================
// DOSE STATUS
// ============================================================

enum DoseStatus { taken, dueNow, upcoming, missed }

extension DoseStatusStyle on DoseStatus {
  String get label {
    switch (this) {
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.dueNow:
        return 'Due now';
      case DoseStatus.upcoming:
        return 'Upcoming';
      case DoseStatus.missed:
        return 'Missed';
    }
  }

  Color get color {
    switch (this) {
      case DoseStatus.taken:
        return const Color(0xFF2E7D32);
      case DoseStatus.dueNow:
        return const Color(0xFFF57C00);
      case DoseStatus.upcoming:
        return const Color(0xFF1976D2);
      case DoseStatus.missed:
        return const Color(0xFFD32F2F);
    }
  }

  Color get background {
    switch (this) {
      case DoseStatus.taken:
        return const Color(0xFFE8F5E9);
      case DoseStatus.dueNow:
        return const Color(0xFFFFF8E1);
      case DoseStatus.upcoming:
        return const Color(0xFFEAF4FF);
      case DoseStatus.missed:
        return const Color(0xFFFDECEA);
    }
  }
}

// Small colored pill: "Taken", "Due now", "Upcoming", "Missed".
class DoseStatusChip extends StatelessWidget {
  final DoseStatus status;

  const DoseStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: status.color,
        ),
      ),
    );
  }
}

// ============================================================
// SMALL HELPERS
// ============================================================

String _two(int value) => value.toString().padLeft(2, '0');

// "2026-10-07"
String dayKey(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

// DateTime -> "02:30 PM"
String clock12(DateTime time) {
  return display12('${_two(time.hour)}:${_two(time.minute)}');
}

// True while a dose was taken recently enough to be undone.
bool withinUndoWindow(DateTime takenAt, DateTime now) {
  return now.difference(takenAt).inMinutes < undoWindowMinutes;
}

// Same medicine + same day + same time always gives the same id,
// so marking a dose twice can never create a duplicate.
String doseId(String medicationId, String day, String time) {
  return '${medicationId}_${day}_${time.replaceAll(':', '')}';
}

// Today's date at a given "HH:mm" time.
DateTime _at(DateTime day, String time) {
  final parts = normalizeTime(time).split(':');

  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

// ============================================================
// DOSE LOG (one saved record per tap)
// ============================================================

class DoseLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String date; // "2026-10-07"
  final String? scheduledTime; // "08:00", or null for "As needed" doses
  final DateTime takenAt; // when the user actually tapped

  const DoseLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.date,
    required this.scheduledTime,
    required this.takenAt,
  });
}

// ============================================================
// SHARED STATE
// ============================================================

final ValueNotifier<List<DoseLog>> doseLogNotifier =
    ValueNotifier<List<DoseLog>>([]);

// Ticks every 30 seconds so "Due now" / "Missed" and the new day
// update on their own while the app is open.
final ValueNotifier<DateTime> clockNotifier = ValueNotifier<DateTime>(
  DateTime.now(),
);

// ============================================================
// SYNC: call startDoseSync() once in main(), after startMedicationSync()
// ============================================================

StreamSubscription<User?>? _authSub;
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _logSub;
Timer? _clockTimer;

void startDoseSync() {
  _authSub?.cancel();
  _clockTimer?.cancel();

  _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    clockNotifier.value = DateTime.now();
  });

  _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
    _logSub?.cancel();
    _logSub = null;

    if (user == null) {
      doseLogNotifier.value = [];
      return;
    }

    final since = dayKey(DateTime.now().subtract(Duration(days: historyDays)));

    _logSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('doseLogs')
        .where('date', isGreaterThanOrEqualTo: since)
        .snapshots()
        .listen((snapshot) {
          final logs = snapshot.docs.map(_logFromDoc).toList()
            ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

          doseLogNotifier.value = logs;
        }, onError: _logError);
  });
}

void stopDoseSync() {
  _logSub?.cancel();
  _authSub?.cancel();
  _clockTimer?.cancel();
  _logSub = null;
  _authSub = null;
  _clockTimer = null;
  doseLogNotifier.value = [];
}

DoseLog _logFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();

  return DoseLog(
    id: doc.id,
    medicationId: data['medicationId'] as String? ?? '',
    medicationName: data['medicationName'] as String? ?? '',
    dosage: data['dosage'] as String? ?? '',
    date: data['date'] as String? ?? '',
    scheduledTime: data['scheduledTime'] as String?,
    takenAt: (data['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

CollectionReference<Map<String, dynamic>>? _logs() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('doseLogs');
}

void _logError(Object error) {
  debugPrint('Firestore error: $error');
}

// ============================================================
// ACTIONS
// ============================================================

// Marks one scheduled dose (for example "Amoxicillin at 14:00") as taken.
void markDoseTaken(Medication medication, String time) {
  final now = DateTime.now();
  final today = dayKey(now);

  _logs()
      ?.doc(doseId(medication.id, today, time))
      .set({
        'medicationId': medication.id,
        'medicationName': medication.name,
        'dosage': medication.dosage,
        'date': today,
        'scheduledTime': time,
        'takenAt': FieldValue.serverTimestamp(),
      })
      .catchError(_logError);
}

// Undo a dose that was marked taken by mistake.
void undoDose(ScheduledDose dose) {
  _logs()?.doc(dose.id).delete().catchError(_logError);
}

// "As needed" medicines: log a dose any time.
void logAsNeededDose(Medication medication) {
  _logs()
      ?.add({
        'medicationId': medication.id,
        'medicationName': medication.name,
        'dosage': medication.dosage,
        'date': dayKey(DateTime.now()),
        'scheduledTime': null,
        'takenAt': FieldValue.serverTimestamp(),
      })
      .then((_) {}, onError: _logError);
}

void deleteDoseLog(String logId) {
  _logs()?.doc(logId).delete().catchError(_logError);
}

// ============================================================
// TODAY'S DOSES
// ============================================================

class ScheduledDose {
  final Medication medication;
  final String time; // 24-hour "HH:mm"
  final DateTime scheduledAt;
  final DoseLog? log;
  final DoseStatus status;

  const ScheduledDose({
    required this.medication,
    required this.time,
    required this.scheduledAt,
    required this.log,
    required this.status,
  });

  bool get taken => log != null;

  bool canUndo(DateTime now) {
    final takenAt = log?.takenAt;
    return takenAt != null && withinUndoWindow(takenAt, now);
  }

  String get id => doseId(medication.id, dayKey(scheduledAt), time);
}

// Short summary for a medicine card (for example "2/3 doses").
class MedicationDayStatus {
  final String label;
  final bool complete;

  const MedicationDayStatus(this.label, this.complete);
}

class TodaySnapshot {
  final DateTime now;
  final List<Medication> medications;
  final List<ScheduledDose> doses; // sorted by time
  final List<Medication> asNeededMedications;
  final List<DoseLog> asNeededLogs; // today only
  final List<DoseLog> recentLogs; // newest first

  const TodaySnapshot._({
    required this.now,
    required this.medications,
    required this.doses,
    required this.asNeededMedications,
    required this.asNeededLogs,
    required this.recentLogs,
  });

  factory TodaySnapshot.current() {
    final now = DateTime.now();
    final today = dayKey(now);
    final medications = medicationNotifier.value;
    final logs = doseLogNotifier.value;

    final todayLogs = {
      for (final log in logs)
        if (log.date == today) log.id: log,
    };

    final doses = <ScheduledDose>[];
    final asNeededMedications = <Medication>[];

    for (final medication in medications) {
      if (isAsNeeded(medication.frequency)) {
        asNeededMedications.add(medication);
        continue;
      }

      // {...list} removes duplicate times but keeps the order.
      for (final time in {...medication.times}) {
        final scheduledAt = _at(now, time);
        final log = todayLogs[doseId(medication.id, today, time)];
        final created = medication.createdAt;

        // A medicine added at 3 PM should not start the day with
        // "Missed" doses from this morning.
        if (log == null &&
            created != null &&
            dayKey(created) == today &&
            scheduledAt.isBefore(created)) {
          continue;
        }

        doses.add(
          ScheduledDose(
            medication: medication,
            time: normalizeTime(time),
            scheduledAt: scheduledAt,
            log: log,
            status: _statusFor(scheduledAt, now, log != null),
          ),
        );
      }
    }

    doses.sort((a, b) {
      final byTime = a.scheduledAt.compareTo(b.scheduledAt);
      if (byTime != 0) return byTime;
      return a.medication.name.compareTo(b.medication.name);
    });

    return TodaySnapshot._(
      now: now,
      medications: medications,
      doses: doses,
      asNeededMedications: asNeededMedications,
      asNeededLogs: logs
          .where((log) => log.date == today && log.scheduledTime == null)
          .toList(),
      recentLogs: logs.take(15).toList(),
    );
  }

  static DoseStatus _statusFor(DateTime scheduledAt, DateTime now, bool taken) {
    if (taken) return DoseStatus.taken;

    final minutesAfter = now.difference(scheduledAt).inMinutes;

    if (minutesAfter < -dueBeforeMinutes) return DoseStatus.upcoming;
    if (minutesAfter <= missedAfterMinutes) return DoseStatus.dueNow;
    return DoseStatus.missed;
  }

  int get scheduledCount => doses.length;

  int get takenCount => doses.where((dose) => dose.taken).length;

  List<ScheduledDose> dosesFor(String medicationId) {
    return doses.where((dose) => dose.medication.id == medicationId).toList();
  }

  List<DoseLog> asNeededLogsFor(String medicationId) {
    return asNeededLogs
        .where((log) => log.medicationId == medicationId)
        .toList();
  }

  MedicationDayStatus statusFor(Medication medication) {
    if (isAsNeeded(medication.frequency)) {
      final count = asNeededLogsFor(medication.id).length;

      return MedicationDayStatus(
        count == 0 ? 'As needed' : '$count logged',
        count > 0,
      );
    }

    final list = dosesFor(medication.id);

    if (list.isEmpty) return const MedicationDayStatus('No doses', false);

    final taken = list.where((dose) => dose.taken).length;

    return MedicationDayStatus(
      '$taken/${list.length} doses',
      taken == list.length,
    );
  }
}

// Rebuilds whenever medicines, dose logs, or the clock change.
class TodayBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, TodaySnapshot today) builder;

  const TodayBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        medicationNotifier,
        doseLogNotifier,
        clockNotifier,
      ]),
      builder: (context, _) => builder(context, TodaySnapshot.current()),
    );
  }
}
