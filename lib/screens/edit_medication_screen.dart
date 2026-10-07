import 'package:flutter/material.dart';

import '../data/sample_medications.dart';
import '../models/medication.dart';
import '../widgets/dose_times_field.dart';

class EditMedicationScreen extends StatefulWidget {
  final String medicationId;

  const EditMedicationScreen({super.key, required this.medicationId});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final notesController = TextEditingController();

  String frequency = 'Once a day';
  String instructions = 'Take with water';
  List<String> times = ['08:00'];

  Medication? medication;

  @override
  void initState() {
    super.initState();

    final matches = medicationNotifier.value.where(
      (item) => item.id == widget.medicationId,
    );

    if (matches.isNotEmpty) {
      medication = matches.first;

      nameController.text = medication!.name;
      dosageController.text = medication!.dosage;
      notesController.text = medication!.notes;

      frequency = medication!.frequency;
      instructions = medication!.instructions;

      // Makes sure the number of times matches the frequency
      // (older medicines only had one time saved).
      times = timesForFrequency(frequency, medication!.times);
    }
  }

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

  void saveChanges() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (medication == null) {
      return;
    }

    final updated = medication!.copyWith(
      name: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      frequency: frequency,
      times: times,
      instructions: instructions,
      notes: notesController.text.trim(),
    );

    updateMedication(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine updated successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (medication == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Medicine')),
        body: const Center(child: Text('Medication not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Medicine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Medicine name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                prefixIcon: Icon(Icons.scale_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Dosage is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: instructions,
              decoration: const InputDecoration(
                labelText: 'Instructions',
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
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
