import 'package:flutter/material.dart';

import '../data/sample_medications.dart';
import '../models/medication.dart';

import 'edit_medication_screen.dart';

class MedicationDetailsScreen extends StatelessWidget {
  final String medicationId;

  const MedicationDetailsScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Medication>>(
      valueListenable: medicationNotifier,
      builder: (context, medications, _) {
        final matches = medications.where((item) => item.id == medicationId);

        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Medicine')),
            body: const Center(child: Text('Medication no longer exists.')),
          );
        }

        final medication = matches.first;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Medicine Details'),
            actions: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditMedicationScreen(medicationId: medication.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () {
                  _confirmDelete(context, medication);
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        size: 42,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      medication.dosage,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _infoTile(Icons.access_time, 'Medication Time', medication.time),
              _infoTile(Icons.repeat, 'Frequency', medication.frequency),
              _infoTile(
                Icons.info_outline,
                'Instructions',
                medication.instructions,
              ),
              _infoTile(
                Icons.notes_outlined,
                'Notes',
                medication.notes.isEmpty ? 'No notes' : medication.notes,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: medication.taken
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      medication.taken ? Icons.check_circle : Icons.schedule,
                      color: medication.taken
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57C00),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        medication.taken
                            ? 'This medication has been marked as taken.'
                            : 'This medication has not been taken yet.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Medicine?'),
          content: Text('Are you sure you want to delete ${medication.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                deleteMedication(medication.id);

                Navigator.pop(dialogContext);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicine deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
