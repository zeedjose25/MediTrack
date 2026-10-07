import 'package:flutter/material.dart';

import '../data/dose_tracking.dart';
import '../widgets/medication_card.dart';

import 'add_medication_screen.dart';
import 'medication_details_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return TodayBuilder(
      builder: (context, today) {
        final filtered = today.medications.where((medication) {
          return medication.name.toLowerCase().contains(
            searchText.toLowerCase(),
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Medicines',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMedicationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search medicine...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final medication = filtered[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MedicationCard(
                              medication: medication,
                              status: today.statusFor(medication),
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
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No medicines found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ],
      ),
    );
  }
}
