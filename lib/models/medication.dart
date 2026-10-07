import 'package:flutter/material.dart';

// ============================================================
// TIME HELPERS
//
// Times are stored as 24-hour "HH:mm" text (for example "14:30")
// and shown to the user as "02:30 PM".
// ============================================================

// Accepts "14:30", "2:30 PM" or "02:30 PM" and returns "14:30".
String normalizeTime(String value) {
  try {
    final parts = value.trim().split(' ');
    final hm = parts[0].split(':');

    int hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);

    if (parts.length > 1) {
      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '08:00';
  }
}

String formatTime24(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

TimeOfDay parseTime24(String value) {
  final parts = normalizeTime(value).split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

// "14:30" -> "02:30 PM"
String display12(String value) {
  final parts = normalizeTime(value).split(':');
  final hour = int.parse(parts[0]);
  final minute = parts[1];

  final period = hour >= 12 ? 'PM' : 'AM';
  final shownHour = hour % 12 == 0 ? 12 : hour % 12;

  return '${shownHour.toString().padLeft(2, '0')}:$minute $period';
}

// ============================================================
// FREQUENCY HELPERS
// ============================================================

// "Once a day" -> 1, "Twice a day" -> 2, "3 times a day" -> 3
int? fixedDoseCount(String frequency) {
  switch (frequency) {
    case 'Once a day':
      return 1;
    case 'Twice a day':
      return 2;
    case '3 times a day':
      return 3;
    default:
      return null;
  }
}

// "Every 6 hours" -> 6
int? intervalHours(String frequency) {
  switch (frequency) {
    case 'Every 4 hours':
      return 4;
    case 'Every 6 hours':
      return 6;
    case 'Every 8 hours':
      return 8;
    default:
      return null;
  }
}

bool isAsNeeded(String frequency) => frequency == 'As needed';

// Returns the dose times that match a frequency.
// - Once / Twice / 3 times a day: keeps the times already chosen and
//   fills any missing ones with sensible defaults.
// - Every X hours: builds the whole day from the first dose time.
// - As needed: no scheduled times.
List<String> timesForFrequency(String frequency, List<String> current) {
  final fixed = fixedDoseCount(frequency);

  if (fixed != null) {
    const defaults = {
      1: ['08:00'],
      2: ['08:00', '20:00'],
      3: ['08:00', '14:00', '20:00'],
    };

    final defaultTimes = defaults[fixed]!;

    return List.generate(
      fixed,
      (i) => i < current.length ? current[i] : defaultTimes[i],
    );
  }

  final interval = intervalHours(frequency);

  if (interval != null) {
    final anchor = current.isNotEmpty ? normalizeTime(current.first) : '08:00';
    final parts = anchor.split(':');
    final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final count = 24 ~/ interval;

    return List.generate(count, (i) {
      final minutes = (start + i * interval * 60) % (24 * 60);

      return '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
          '${(minutes % 60).toString().padLeft(2, '0')}';
    });
  }

  if (isAsNeeded(frequency)) {
    return [];
  }

  return current.isEmpty ? ['08:00'] : current;
}

// ============================================================
// MEDICATION MODEL
// ============================================================

class Medication {
  final String id;
  String name;
  String dosage;
  String frequency;
  List<String> times; // 24-hour "HH:mm", one per dose
  String instructions;
  String notes;
  bool reminderEnabled;
  IconData icon;
  final DateTime?
  createdAt; // used so doses before it was added aren't "missed"

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.instructions,
    this.notes = '',
    this.reminderEnabled = true,
    this.icon = Icons.medication_rounded,
    this.createdAt,
  });

  // Short text for cards and lists: "08:00 AM" or "08:00 AM +2 more".
  String get time {
    if (times.isEmpty) return 'As needed';

    final first = display12(times.first);

    if (times.length == 1) return first;

    return '$first +${times.length - 1} more';
  }

  Medication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    String? instructions,
    String? notes,
    bool? reminderEnabled,
    IconData? icon,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      icon: icon ?? this.icon,
      createdAt: createdAt,
    );
  }
}
