import 'package:flutter/material.dart';

import '../data/sample_medications.dart';
import '../models/medication.dart';

import 'medication_details_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final dateText =
        '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}';

    return ValueListenableBuilder<List<Medication>>(
      valueListenable: medicationNotifier,
      builder: (context, medications, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Schedule',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 12),

              if (medications.isEmpty)
                _emptySchedule()
              else
                ...medications.map(
                  (medication) => _scheduleItem(context, medication),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleItem(BuildContext context, Medication medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: medication.taken
              ? const Color(0xFFB7E4C7)
              : const Color(0xFFE1E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Color(0xFF1976D2),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.dosage,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 17,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    medication.time,
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  medication.taken ? 'Dose taken' : 'Dose not taken',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: medication.taken
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57C00),
                  ),
                ),
              ),

              FilledButton.icon(
                onPressed: () {
                  toggleMedicationTaken(medication.id);
                },
                icon: Icon(medication.taken ? Icons.undo : Icons.check),
                label: Text(medication.taken ? 'Undo' : 'Mark as Taken'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MedicationDetailsScreen(medicationId: medication.id),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySchedule() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No medications scheduled',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Your medication schedule is currently empty.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
