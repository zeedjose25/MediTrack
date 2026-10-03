import 'package:flutter/material.dart';

import '../data/sample_medications.dart';
import '../models/medication.dart';
import '../widgets/medication_card.dart';

import 'add_medication_screen.dart';
import 'medication_details_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Medication>>(
      valueListenable: medicationNotifier,
      builder: (context, medications, _) {
        final taken = medications.where((item) => item.taken).length;

        final total = medications.length;

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning!',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'MediTrack',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _welcomeCard(),

              const SizedBox(height: 20),

              _progressCard(total, taken),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // TODAY'S MEDICATIONS
              // --------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Medications",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScheduleScreen(),
                        ),
                      );
                    },
                    child: const Text('Schedule'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (medications.isEmpty)
                _emptyMedication(context)
              else
                ...medications.map(
                  (medication) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicationCard(
                      medication: medication,

                      // Home can VIEW medication details,
                      // but cannot mark the medicine as taken.
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicationDetailsScreen(
                              medicationId: medication.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // QUICK ACTIONS
              // --------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.add_circle_outline,
                      title: 'Add Medicine',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddMedicationScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _actionButton(
                      icon: Icons.calendar_month_outlined,
                      title: 'View Schedule',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScheduleScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay on track',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Keep your medication schedule organized.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS CARD
  // ============================================================

  Widget _progressCard(int total, int taken) {
    final progress = total == 0 ? 0.0 : taken / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFE8EEF5),
                  color: const Color(0xFF1976D2),
                ),

                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Progress",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),

                const SizedBox(height: 5),

                Text(
                  '$taken of $total medications taken',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY MEDICATION STATE
  // ============================================================

  Widget _emptyMedication(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined, size: 50, color: Colors.grey),

          const SizedBox(height: 10),

          const Text(
            'No medications yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 5),

          const Text(
            'Add your first medication to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 15),

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1976D2), size: 28),

            const SizedBox(height: 8),

            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
