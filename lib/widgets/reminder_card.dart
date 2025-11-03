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
    if (!widget.reminder.containsKey('hour')) return false;
    final now = DateTime.now();
    final reminderTime = TimeOfDay(
      hour: widget.reminder['hour'],
      minute: widget.reminder['minute'],
    );

    final reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    final difference = now.difference(reminderDateTime).inMinutes;
    return difference >= 0 && difference <= 60; // 1h de tolerancia
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
    final isDoctorCreated = r['created_by_doctor'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(r['name'] ?? 'Sin nombre'),
        subtitle: Text(
          'Hora: ${r['hour']}:${r['minute'].toString().padLeft(2, '0')}',
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