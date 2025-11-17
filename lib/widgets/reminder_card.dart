import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/auth_service.dart';

class ReminderCard extends StatefulWidget {
  final String reminderId;
  final Map<String, dynamic> reminder;
  final bool isDoctorView;

  const ReminderCard({
    super.key,
    required this.reminderId,
    required this.reminder,
    this.isDoctorView = false,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();

  bool _isLoading = false;

  bool get isWithinTakeWindow {
    final now = DateTime.now();
    final times = (widget.reminder['times'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    if (times.isEmpty) return false;

    // buscar próxima hora programada para hoy
    for (var t in times) {
      final parts = t.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final scheduled = DateTime(now.year, now.month, now.day, h, m);
      final diff = now.difference(scheduled).inMinutes;
      if (diff >= 0 && diff <= 60) return true; // ventana 1h
    }
    return false;
  }

  Future<void> _markAsTaken() async {
    setState(() => _isLoading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('reminder_logs').add({
      'reminder_id': widget.reminderId,
      'user_id': uid,
      'timestamp': DateTime.now(),
      'status': 'taken',
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dosis marcada como tomada')));
    setState(() => _isLoading = false);
  }

  Future<void> _deleteReminder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: const Text('¿Seguro que deseas eliminar este recordatorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('reminders').doc(widget.reminderId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recordatorio eliminado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    final isDoctorCreated = (r['doctorId'] != null);
    final times = (r['times'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final timeText = times.isNotEmpty ? times.join(', ') : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(r['name'] ?? 'Sin nombre'),
        subtitle: Text(
          'Horas: $timeText',
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWithinTakeWindow)
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: _markAsTaken,
                    ),
                  if (!isDoctorCreated)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _deleteReminder,
                    ),
                ],
              ),
      ),
    );
  }
}