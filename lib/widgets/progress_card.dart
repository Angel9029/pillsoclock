import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressCard extends StatelessWidget {
  final String reminderId;
  final String name;
  final String description;
  final List<String> times;
  final DateTime? startDate;
  final DateTime? endDate;
  final double progress; // ✅ ahora viene directo del FutureBuilder
  final int takenDatesLenght; // ✅ opcional

  const ProgressCard({
    super.key,
    required this.reminderId,
    required this.name,
    required this.description,
    required this.times,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.takenDatesLenght,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(0);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de medicamento
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety, color: Colors.teal),
            ),
            const SizedBox(width: 12),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Horas: ${times.join(', ')}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                  if (startDate != null)
                    Text(
                      'Inicio  : ${DateFormat('dd/MM/yyyy').format(startDate!.toLocal())}\nFin      :  ${DateFormat('dd/MM/yyyy').format(endDate!.toLocal())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 10),

                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.teal.withOpacity(0.15),
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // if (dosesToday > 0)
                    Text(
                      'Tomadas hoy: $takenDatesLenght ✅',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
