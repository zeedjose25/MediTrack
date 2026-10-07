import 'package:flutter/material.dart';

import '../data/dose_tracking.dart';
import '../models/medication.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TodayBuilder(
      builder: (context, today) {
        final doses = today.doses;
        final recent = today.recentLogs;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Alerts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --------------------------------------------------
              // HEADER
              // --------------------------------------------------

              _buildHeaderCard(),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // TODAY'S REMINDERS
              // --------------------------------------------------
              _buildSectionTitle(
                'Today\'s Reminders',
                'Every scheduled dose for today',
              ),

              const SizedBox(height: 12),

              if (doses.isEmpty)
                _buildEmptyReminders()
              else
                ...doses.map(
                  (dose) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTodayReminder(dose),
                  ),
                ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // RECENT ACTIVITY
              // --------------------------------------------------
              _buildSectionTitle('Recent Activity', 'Your most recent doses'),

              const SizedBox(height: 12),

              if (recent.isEmpty)
                _buildNoActivity()
              else
                ...recent.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildActivityItem(log, today.now),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Keep track of your medication reminders and daily progress.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172B4D),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  // ============================================================
  // TODAY'S REMINDER
  // ============================================================

  Widget _buildTodayReminder(ScheduledDose dose) {
    final medication = dose.medication;
    final bool taken = dose.taken;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: taken ? const Color(0xFFB7E4C7) : const Color(0xFFE1E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: taken ? const Color(0xFFE8F5E9) : const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              taken ? Icons.check_circle : Icons.medication_rounded,
              color: taken ? const Color(0xFF2E7D32) : const Color(0xFF1976D2),
              size: 27,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  medication.dosage,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 15,
                      color: Color(0xFF1976D2),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      display12(dose.time),
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          DoseStatusChip(status: dose.status),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _buildActivityItem(DoseLog log, DateTime now) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.check, color: Color(0xFF2E7D32)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.medicationName} taken',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 3),

                Text(
                  '${log.dosage} • ${_whenText(log, now)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 21),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY REMINDERS
  // ============================================================

  Widget _buildEmptyReminders() {
    return _emptyCard(
      Icons.medication_outlined,
      'No medications yet',
      'Add a medication and it will appear here.',
    );
  }

  // ============================================================
  // EMPTY ACTIVITY
  // ============================================================

  Widget _buildNoActivity() {
    return _emptyCard(
      Icons.history,
      'No activity yet',
      'Medications marked as taken will appear here.',
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 45, color: Colors.grey),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHEN A DOSE WAS TAKEN
  // ============================================================

  // "Today, 08:12 AM" / "Yesterday, 08:12 AM" / "Oct 3, 08:12 AM"
  String _whenText(DoseLog log, DateTime now) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final taken = log.takenAt;
    final yesterday = now.subtract(const Duration(days: 1));

    String day;

    if (dayKey(taken) == dayKey(now)) {
      day = 'Today';
    } else if (dayKey(taken) == dayKey(yesterday)) {
      day = 'Yesterday';
    } else {
      day = '${months[taken.month - 1]} ${taken.day}';
    }

    return '$day, ${clock12(taken)}';
  }
}
