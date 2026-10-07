import 'package:flutter/material.dart';

import '../data/sample_medications.dart';
import '../models/medication.dart';
import '../widgets/dose_times_field.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final notesController = TextEditingController();

  String frequency = 'Once a day';
  String instructions = 'Take with water';
  List<String> times = ['08:00'];

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void onFrequencyChanged(String value) {
    setState(() {
      frequency = value;
      times = timesForFrequency(value, times);
    });
  }

  void saveMedication() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      frequency: frequency,
      times: times,
      instructions: instructions,
      notes: notesController.text.trim(),
    );

    addMedication(medication);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication added successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Medicine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Medicine Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                hintText: 'e.g. Amoxicillin',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the medicine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 500 mg',
                prefixIcon: Icon(Icons.scale_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionTitle('Schedule'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                prefixIcon: Icon(Icons.repeat),
              ),
              items:
                  const [
                    'Once a day',
                    'Twice a day',
                    '3 times a day',
                    'Every 4 hours',
                    'Every 6 hours',
                    'Every 8 hours',
                    'As needed',
                  ].map((value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onFrequencyChanged(value);
                }
              },
            ),
            const SizedBox(height: 14),
            DoseTimesField(
              frequency: frequency,
              times: times,
              onChanged: (updated) {
                setState(() {
                  times = updated;
                });
              },
            ),
            const SizedBox(height: 24),
            _sectionTitle('Instructions'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: instructions,
              decoration: const InputDecoration(
                labelText: 'How should it be taken?',
                prefixIcon: Icon(Icons.info_outline),
              ),
              items:
                  const [
                    'Take with water',
                    'Take with food',
                    'Take after meals',
                    'Take before meals',
                    'As directed',
                  ].map((value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    instructions = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional notes...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: saveMedication,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Medicine'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF172B4D),
      ),
    );
  }
}
