import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressCard extends StatelessWidget {
  final String reminderId;
  final String name;
  final String description;
  final List<String> times;
  final DateTime? startDate;
  final DateTime? endDate;
  final double progress;
  final int takenDatesLenght;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onProgress;

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
    this.onEdit,
    this.onDelete,
    this.onProgress,
  });

  ProgressCard withActions({
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onProgress,
  }) {
    return ProgressCard(
      reminderId: reminderId,
      name: name,
      description: description,
      times: times,
      startDate: startDate,
      endDate: endDate,
      progress: progress,
      takenDatesLenght: takenDatesLenght,
      onEdit: onEdit,
      onDelete: onDelete,
      onProgress: onProgress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(0);
    final progressColor = progress >= 0.75
        ? Colors.green
        : progress >= 0.5
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: nombre + acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.health_and_safety, color: Colors.teal, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Botones de acción
                if (onEdit != null || onDelete != null || onProgress != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'progress') onProgress?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      if (onProgress != null)
                        const PopupMenuItem(value: 'progress', child: Text('Ver progreso')),
                      if (onDelete != null)
                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Detalles
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('⏰ Horas', times.join(', ')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (startDate != null)
              _buildDetailRow(
                '📅 Período',
                '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate ?? DateTime.now())}',
              ),

            const SizedBox(height: 14),

            // Progress bar con porcentaje
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: progressColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: progressColor, fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tomas registradas
            Text(
              'Tomadas: $takenDatesLenght ✅',
              style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
