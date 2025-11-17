import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../core/services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _started = false;

  // Método público del State para abrir el diálogo de crear/editar recordatorio
  void openReminderDialog({ReminderModel? reminder}) {
    final nameCtrl = TextEditingController(text: reminder?.name ?? '');
    final descCtrl = TextEditingController(text: reminder?.description ?? '');
    final timesCtrl = TextEditingController(text: reminder?.times.join(', ') ?? '');
    DateTime startDate = reminder?.startDate ?? DateTime.now().add(const Duration(minutes: 1));
    DateTime endDate = reminder?.endDate ?? DateTime.now().add(const Duration(days: 30));
    String? _timeError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool _validateTimes(String input) {
            if (input.isEmpty) return false;
            final times = input.split(',').map((e) => e.trim()).toList();
            for (var t in times) {
              final parts = t.split(':');
              if (parts.length != 2) return false;
              final h = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
                return false;
              }
            }
            return true;
          }

          return AlertDialog(
            title: Text(reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Horas (ej: 08:00, 20:00)',
                      errorText: _timeError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() => _timeError = _validateTimes(val) ? null : 'Formato inválido. Usa HH:MM separadas por comas'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text('Inicio: ${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}')),
                      IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async {
                        final d = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (d != null) {
                          final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(startDate));
                          if (t != null) setState(() => startDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      }),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Fin: ${DateFormat('yyyy-MM-dd').format(endDate)}')),
                      IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () async {
                        final d = await showDatePicker(context: ctx, initialDate: endDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (d != null) setState(() => endDate = d);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (_timeError != null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('❌ Revisa el formato de horas')));
                    return;
                  }
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('❌ Ingresa un nombre')));
                    return;
                  }
                  final times = timesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  final prov = Provider.of<ReminderProvider>(context, listen: false);

                  if (reminder == null) {
                    final newId = await prov.addReminder(ReminderModel(id: '', userId: FirebaseAuth.instance.currentUser!.uid, doctorId: null, name: nameCtrl.text, description: descCtrl.text, times: times, startDate: startDate, endDate: endDate, takenDates: [], immutable: false));
                    // programar localmente
                    for (int i = 0; i < times.length; i++) {
                      final parts = times[i].split(':');
                      if (parts.length != 2) continue;
                      final hour = int.tryParse(parts[0]) ?? 0;
                      final minute = int.tryParse(parts[1]) ?? 0;
                      await NotificationService.scheduleDailyNotification(id: '${newId}_$i'.hashCode, title: 'Recordatorio: ${nameCtrl.text}', body: descCtrl.text.isNotEmpty ? descCtrl.text : 'Es hora de tu dosis', hour: hour, minute: minute, payload: newId);
                    }
                  } else {
                    final updated = reminder.copyWith(name: nameCtrl.text, description: descCtrl.text, times: times, startDate: startDate, endDate: endDate);
                    await prov.updateReminder(updated);
                    await NotificationService.cancelNotificationsByPrefix(reminder.id);
                    for (int i = 0; i < times.length; i++) {
                      final parts = times[i].split(':');
                      if (parts.length != 2) continue;
                      final hour = int.tryParse(parts[0]) ?? 0;
                      final minute = int.tryParse(parts[1]) ?? 0;
                      await NotificationService.scheduleDailyNotification(id: '${reminder.id}_$i'.hashCode, title: 'Recordatorio: ${nameCtrl.text}', body: descCtrl.text.isNotEmpty ? descCtrl.text : 'Es hora de tu dosis', hour: hour, minute: minute, payload: reminder.id);
                    }
                  }

                  Navigator.pop(ctx);
                },
                child: Text(reminder == null ? 'Crear' : 'Actualizar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ReminderProvider>(context);

    if (!_started) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prov.startForUser(userId);
      });
      _started = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Recordatorios')),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Sin recordatorios', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
               itemCount: prov.reminders.length,
               itemBuilder: (ctx, i) {
                 final r = prov.reminders[i];
                 final now = DateTime.now();

                 bool isWithinTakeWindow = r.times.any((t) {
                   final parts = t.split(':');
                   if (parts.length != 2) return false;
                   final h = int.tryParse(parts[0]);
                   final m = int.tryParse(parts[1]) ?? 0;
                   if (h == null) return false;
                   final reminderTime = DateTime(
                     now.year,
                     now.month,
                     now.day,
                     h,
                     m,
                   );
                   return now.isAfter(
                         reminderTime.subtract(const Duration(minutes: 30)),
                       ) &&
                       now.isBefore(
                         reminderTime.add(const Duration(minutes: 30)),
                       );
                 });

                 // ✅ Revisa si ya existe una toma dentro de esta ventana
                 bool hasTakenInCurrentWindow = r.takenDates.any((d) {
                   final diff = now.difference(d).inMinutes.abs();
                   return diff <= 30;
                 });

                 final progress = prov.computeProgress(r);

                 return _buildReminderCard(r, isWithinTakeWindow, hasTakenInCurrentWindow, progress, prov);
               },
            ),
       floatingActionButton: FloatingActionButton(
         backgroundColor: Colors.teal,
         onPressed: () => openReminderDialog(),
         child: const Icon(Icons.add_rounded),
       ),
     );
  }

  Widget _buildReminderCard(
    ReminderModel r,
    bool isWithinTakeWindow,
    bool hasTakenInCurrentWindow,
    double progress,
    ReminderProvider prov,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Horas: ${r.times.join(", ")}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                if (isWithinTakeWindow && !hasTakenInCurrentWindow)
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                    onPressed: () async {
                      await prov.markTaken(r.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Toma registrada')),
                      );
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.teal.withOpacity(0.15),
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% completado',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            if (!r.immutable)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openReminderDialog(reminder: r),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async => await prov.deleteReminder(r.id),
                      icon: const Icon(Icons.delete_rounded, size: 16),
                      label: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
