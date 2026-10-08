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

        final remaining = today.scheduledCount - today.takenCount;

        // A dose that was just taken stays in "To take" (with Undo) until the
        // undo window closes, then it moves into "Completed".
        final active = today.doses
            .where((dose) => !dose.taken || dose.canUndo(now))
            .toList();
        final completed = today.doses
            .where((dose) => dose.taken && !dose.canUndo(now))
            .toList();

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
              _summaryCard(dateText, today),

              const SizedBox(height: 22),

              if (isEmpty)
                _emptySchedule()
              else ...[
                if (today.doses.isEmpty)
                  const Text(
                    'No scheduled doses today.',
                    style: TextStyle(color: Colors.grey),
                  )
                else ...[
                  _sectionHeader(
                    'To take',
                    remaining == 0 ? 'All done' : '$remaining left',
                  ),
                  const SizedBox(height: 10),

                  if (active.isEmpty)
                    _allDoneCard()
                  else
                    _groupCard([
                      for (final dose in active) _doseRow(context, dose, now),
                    ]),

                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _completedSection(context, completed, now),
                  ],
                ],

                if (today.asNeededMedications.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionHeader('As needed', 'Log when you take one'),
                  const SizedBox(height: 10),
                  _groupCard([
                    for (final medication in today.asNeededMedications)
                      _asNeededRow(
                        context,
                        medication,
                        today.asNeededLogsFor(medication.id),
                        now,
                      ),
                  ]),
                ],
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SUMMARY CARD (date + progress bar)
  // ============================================================

  Widget _summaryCard(String dateText, TodaySnapshot today) {
    final total = today.scheduledCount;
    final taken = today.takenCount;
    final progress = total == 0 ? 0.0 : taken / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total == 0
                          ? 'No scheduled doses today'
                          : '$taken of $total doses taken',
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
          if (total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER / CARD SHAPES
  // ============================================================

  Widget _sectionHeader(String title, String trailing) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172B4D),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            trailing,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  ShapeBorder _cardShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE1E8F0)),
    );
  }

  // One white card holding many rows, separated by thin dividers.
  Widget _groupCard(List<Widget> rows) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: _cardShape(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _allDoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'All doses taken. Nice work!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED (collapsed by default)
  // ============================================================

  Widget _completedSection(
    BuildContext context,
    List<ScheduledDose> done,
    DateTime now,
  ) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: _cardShape(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const PageStorageKey('completed-doses'),
          leading: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          title: Text(
            'Completed (${done.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          childrenPadding: EdgeInsets.zero,
          children: [
            for (final dose in done) ...[
              const Divider(height: 1, indent: 14, endIndent: 14),
              _doseRow(context, dose, now),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ONE SCHEDULED DOSE (compact row)
  // ============================================================

  Widget _doseRow(BuildContext context, ScheduledDose dose, DateTime now) {
    final medication = dose.medication;
    final status = dose.status;
    final taken = dose.taken;

    final String statusText = switch (status) {
      DoseStatus.taken => 'Taken ${clock12(dose.log!.takenAt)}',
      DoseStatus.upcoming =>
        'Opens ${clock12(dose.scheduledAt.subtract(const Duration(minutes: dueBeforeMinutes)))}',
      _ => status.label,
    };

    final Color statusColor = status == DoseStatus.upcoming
        ? Colors.grey
        : status.color;

    return InkWell(
      onTap: () => _openDetails(context, medication),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: Text(
                display12(dose.time),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: taken ? Colors.grey : const Color(0xFF1976D2),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      children: [
                        TextSpan(text: '${medication.dosage} • '),
                        TextSpan(
                          text: statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _doseAction(dose, now),
          ],
        ),
      ),
    );
  }

  Widget _doseAction(ScheduledDose dose, DateTime now) {
    // Taken: Undo works only for a few minutes, then it is disabled.
    if (dose.taken) {
      return TextButton(
        onPressed: dose.canUndo(now) ? () => undoDose(dose) : null,
        child: const Text('Undo'),
      );
    }

    // Not available yet (more than 5 minutes before the dose).
    if (dose.status == DoseStatus.upcoming) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.schedule, color: Colors.grey, size: 20),
      );
    }

    return FilledButton(
      onPressed: () => markDoseTaken(dose.medication, dose.time),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Text('Take'),
    );
  }

  // ============================================================
  // ONE "AS NEEDED" MEDICINE (compact row)
  // ============================================================

  Widget _asNeededRow(
    BuildContext context,
    Medication medication,
    List<DoseLog> logs,
    DateTime now,
  ) {
    return InkWell(
      onTap: () => _openDetails(context, medication),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        logs.isEmpty
                            ? '${medication.dosage} • none logged today'
                            : '${medication.dosage} • ${logs.length} logged today',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => logAsNeededDose(medication),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final log in logs.reversed)
                    Chip(
                      label: Text(clock12(log.takenAt)),
                      visualDensity: VisualDensity.compact,
                      // Same undo window as scheduled doses.
                      onDeleted: withinUndoWindow(log.takenAt, now)
                          ? () => deleteDoseLog(log.id)
                          : null,
                    ),
                ],
              ),
            ],
          ],
        ),
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
