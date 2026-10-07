import 'package:flutter/material.dart';

import '../models/medication.dart';

// Shows the time picker(s) that match the selected frequency:
// - Once / Twice / 3 times a day: one picker per dose
// - Every 4 / 6 / 8 hours: one picker for the first dose, the rest are automatic
// - As needed: no times
class DoseTimesField extends StatelessWidget {
  final String frequency;
  final List<String> times;
  final ValueChanged<List<String>> onChanged;

  const DoseTimesField({
    super.key,
    required this.frequency,
    required this.times,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parseTime24(times[index]),
    );

    if (picked == null) return;

    final updated = [...times];
    updated[index] = formatTime24(picked);

    // For "Every X hours", the other doses follow from the first one.
    onChanged(
      intervalHours(frequency) != null
          ? timesForFrequency(frequency, updated)
          : updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAsNeeded(frequency)) {
      return _note('As-needed medicines have no scheduled times or reminders.');
    }

    if (times.isEmpty) {
      return _note('No dose times set.');
    }

    final interval = intervalHours(frequency);

    if (interval != null) {
      return Column(
        children: [
          _picker(context, label: 'First dose time', index: 0),
          const SizedBox(height: 10),
          _note('Doses at: ${times.map(display12).join(', ')}'),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < times.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _picker(
            context,
            label: times.length == 1 ? 'Medication time' : 'Dose ${i + 1} time',
            index: i,
          ),
        ],
      ],
    );
  }

  Widget _picker(
    BuildContext context, {
    required String label,
    required int index,
  }) {
    return InkWell(
      onTap: () => _pick(context, index),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(display12(times[index])),
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF40566F), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
