import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/medication.dart';

// ============================================================
// SHARED LIST (the screens listen to this, same as before)
// ============================================================

final ValueNotifier<List<Medication>> medicationNotifier =
    ValueNotifier<List<Medication>>([]);

// ============================================================
// SYNC: call startMedicationSync() once in main()
//
// - When a user signs in, it starts listening to
//   users/{uid}/medications in Firestore.
// - When the user signs out, it stops and clears the list.
// ============================================================

StreamSubscription<User?>? _authSub;
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _medSub;

void startMedicationSync() {
  _authSub?.cancel();

  _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
    _medSub?.cancel();
    _medSub = null;

    if (user == null) {
      medicationNotifier.value = [];
      return;
    }

    _medSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .snapshots()
        .listen((snapshot) {
          final docs = snapshot.docs.toList()
            ..sort((a, b) {
              final ta =
                  (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final tb =
                  (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              return ta.compareTo(tb);
            });

          medicationNotifier.value = docs.map(_fromDoc).toList();
        }, onError: _logError);
  });
}

void stopMedicationSync() {
  _medSub?.cancel();
  _authSub?.cancel();
  _medSub = null;
  _authSub = null;
  medicationNotifier.value = [];
}

// ============================================================
// HELPERS
// ============================================================

CollectionReference<Map<String, dynamic>>? _collection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('medications');
}

void _logError(Object error) {
  debugPrint('Firestore error: $error');
}

Map<String, dynamic> _toMap(Medication medication) {
  return {
    'name': medication.name,
    'dosage': medication.dosage,
    'frequency': medication.frequency,
    'times': medication.times,
    'instructions': medication.instructions,
    'notes': medication.notes,
    'reminderEnabled': medication.reminderEnabled,
  };
}

// Reads the dose times. Older medicines only have a single "time" text
// (like "08:00 AM"), so that is converted into a one-item list.
List<String> _readTimes(Map<String, dynamic> data) {
  final raw = data['times'];

  if (raw is List) {
    return raw.map((item) => normalizeTime(item.toString())).toList();
  }

  final oldTime = data['time'] as String?;

  return [oldTime == null ? '08:00' : normalizeTime(oldTime)];
}

Medication _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();

  return Medication(
    id: doc.id,
    name: data['name'] as String? ?? '',
    dosage: data['dosage'] as String? ?? '',
    frequency: data['frequency'] as String? ?? 'Once a day',
    times: _readTimes(data),
    instructions: data['instructions'] as String? ?? 'As directed',
    notes: data['notes'] as String? ?? '',
    reminderEnabled: data['reminderEnabled'] as bool? ?? true,
    // Pending (not yet saved) documents have no server time yet.
    createdAt:
        (data['createdAt'] as Timestamp?)?.toDate() ??
        (doc.metadata.hasPendingWrites ? DateTime.now() : null),
  );
}

// ============================================================
// ACTIONS (same names and signatures as before)
// ============================================================

void addMedication(Medication medication) {
  _collection()
      ?.doc(medication.id)
      .set({..._toMap(medication), 'createdAt': FieldValue.serverTimestamp()})
      .catchError(_logError);
}

void updateMedication(Medication medication) {
  _collection()
      ?.doc(medication.id)
      .update(_toMap(medication))
      .catchError(_logError);
}

void deleteMedication(String medicationId) {
  _collection()?.doc(medicationId).delete().catchError(_logError);
}

void toggleMedicationReminder(String medicationId) {
  final matches = medicationNotifier.value.where(
    (item) => item.id == medicationId,
  );
  if (matches.isEmpty) return;

  _collection()
      ?.doc(medicationId)
      .update({'reminderEnabled': !matches.first.reminderEnabled})
      .catchError(_logError);
}
