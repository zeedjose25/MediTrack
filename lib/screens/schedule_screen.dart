import 'package:flutter/material.dart';

import '../data/dose_tracking.dart';
import '../models/medication.dart';

import 'medication_details_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TodayBuilder(
      builder: (context, today) {
        final now = today.now;

        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        const months = [
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

        final progressText = today.scheduledCount == 0
            ? 'No scheduled doses today'
            : '${today.takenCount} of ${today.scheduledCount} doses taken';

        final isEmpty =
            today.doses.isEmpty && today.asNeededMedications.isEmpty;

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
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 4),
                          Text(
                            progressText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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

              if (isEmpty)
                _emptySchedule()
              else ...[
                if (today.doses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'No scheduled doses today.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ...today.doses.map((dose) => _doseItem(context, dose)),
              ],

              if (today.asNeededMedications.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'As Needed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Log a dose whenever you take one.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...today.asNeededMedications.map(
                  (medication) => _asNeededItem(
                    context,
                    medication,
                    today.asNeededLogsFor(medication.id),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ONE SCHEDULED DOSE
  // ============================================================

  Widget _doseItem(BuildContext context, ScheduledDose dose) {
    final medication = dose.medication;
    final status = dose.status;

    Color borderColor = const Color(0xFFE1E8F0);
    if (status == DoseStatus.taken) borderColor = const Color(0xFFB7E4C7);
    if (status == DoseStatus.missed) borderColor = const Color(0xFFF5C6C2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                    display12(dose.time),
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

          if (!dose.taken && status == DoseStatus.upcoming) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available at ${clock12(dose.scheduledAt.subtract(const Duration(minutes: dueBeforeMinutes)))}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              DoseStatusChip(status: status),

              if (dose.log != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'at ${clock12(dose.log!.takenAt)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ] else
                const Spacer(),

              FilledButton.icon(
                // Locked until 5 minutes before the dose. Undo and late doses stay enabled.
                onPressed: (!dose.taken && status == DoseStatus.upcoming)
                    ? null
                    : () {
                        if (dose.taken) {
                          undoDose(dose);
                        } else {
                          markDoseTaken(medication, dose.time);
                        }
                      },
                icon: Icon(dose.taken ? Icons.undo : Icons.check),
                label: Text(dose.taken ? 'Undo' : 'Mark as Taken'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openDetails(context, medication),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONE "AS NEEDED" MEDICINE
  // ============================================================

  Widget _asNeededItem(
    BuildContext context,
    Medication medication,
    List<DoseLog> logs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      logs.isEmpty
                          ? '${medication.dosage} • none logged today'
                          : '${medication.dosage} • ${logs.length} logged today',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final log in logs.reversed)
                  Chip(
                    label: Text(clock12(log.takenAt)),
                    onDeleted: () => deleteDoseLog(log.id),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              FilledButton.icon(
                onPressed: () => logAsNeededDose(medication),
                icon: const Icon(Icons.add),
                label: const Text('Log a dose'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _openDetails(context, medication),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationDetailsScreen(medicationId: medication.id),
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
