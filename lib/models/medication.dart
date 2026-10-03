import 'package:flutter/material.dart';

class Medication {
  final String id;
  String name;
  String dosage;
  String frequency;
  String time;
  String instructions;
  String notes;
  bool taken;
  bool reminderEnabled;
  IconData icon;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.instructions,
    this.notes = '',
    this.taken = false,
    this.reminderEnabled = true,
    this.icon = Icons.medication_rounded,
  });

  Medication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? time,
    String? instructions,
    String? notes,
    bool? taken,
    bool? reminderEnabled,
    IconData? icon,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      taken: taken ?? this.taken,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      icon: icon ?? this.icon,
    );
  }
}
