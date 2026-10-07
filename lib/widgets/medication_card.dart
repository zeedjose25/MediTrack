import 'package:flutter/material.dart';

import '../data/dose_tracking.dart';
import '../models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;

  // Today's dose summary (for example "2/3 doses"). Optional.
  final MedicationDayStatus? status;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final complete = status?.complete ?? false;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  medication.icon,
                  color: const Color(0xFF1976D2),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 15,
                          color: Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          medication.time,
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

              // View-only status for today
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    complete ? Icons.check_circle : Icons.schedule,
                    color: complete ? const Color(0xFF2E7D32) : Colors.grey,
                    size: 28,
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      status!.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: complete ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
