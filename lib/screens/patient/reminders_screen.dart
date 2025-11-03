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

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ReminderProvider>(context);

    if (!_started) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prov.start(userId);
      });
      _started = true;
    }

    void _openReminderDialog({ReminderModel? reminder}) {
      final nameCtrl = TextEditingController(text: reminder?.name ?? '');
      final descCtrl = TextEditingController(text: reminder?.description ?? '');
      final timesCtrl = TextEditingController(
        text: reminder?.times.join(',') ?? '',
      );
      DateTime startDate =
          reminder?.startDate ?? DateTime.now().add(const Duration(minutes: 1));
      DateTime endDate =
          reminder?.endDate ?? DateTime.now().add(const Duration(days: 30));

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(
                reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    TextField(
                      controller: timesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horas (ej: 08:00,20:00)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Inicio: ${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (d != null) {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(startDate),
                              );
                              if (t != null) {
                                setState(() {
                                  startDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    t.hour,
                                    t.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Fin: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (d != null) setState(() => endDate = d);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final times = timesCtrl.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    if (reminder == null) {
                      await prov.addReminder(
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        times: times,
                        startDate: startDate,
                        endDate: endDate,
                      );
                    } else {
                      await prov.updateReminder(reminder.id, {
                        'name': nameCtrl.text,
                        'description': descCtrl.text,
                        'times': times,
                        'startDate': startDate,
                        'endDate': endDate,
                      });
                    }

                    for (var t in times) {
                      final parts = t.split(':');
                      if (parts.length == 2) {
                        final hour = int.tryParse(parts[0]);
                        final minute = int.tryParse(parts[1]);
                        if (hour != null && minute != null) {
                          final notifTime = DateTime(
                            startDate.year,
                            startDate.month,
                            startDate.day,
                            hour,
                            minute,
                          );
                          await NotificationService.scheduleNotification(
                            id: '${reminder?.id ?? ''}_$t'.hashCode,
                            title: 'Recordatorio de medicamento',
                            body:
                                'Hora de tomar tu medicamento: ${nameCtrl.text}',
                            scheduledDate: notifTime,
                            payload: '${reminder?.id ?? ''}_$t',
                          );
                        }
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

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Recordatorios')),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.reminders.isEmpty
          ? const Center(child: Text('No tienes recordatorios.'))
          : ListView.builder(
              itemCount: prov.reminders.length,
              itemBuilder: (ctx, i) {
                final r = prov.reminders[i];
                final now = DateTime.now();

                bool isWithinTakeWindow = false;
                for (var t in r.times) {
                  final parts = t.split(':');
                  if (parts.length == 2) {
                    final h = int.tryParse(parts[0]);
                    final m = int.tryParse(parts[1]) ?? 0;
                    if (h != null) {
                      final reminderTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        h,
                        m,
                      );
                      final startWindow = reminderTime.subtract(
                        const Duration(minutes: 30),
                      );
                      final endWindow = reminderTime.add(
                        const Duration(minutes: 30),
                      );

                      if (now.isAfter(startWindow) && now.isBefore(endWindow)) {
                        isWithinTakeWindow = true;
                        break;
                      }
                    }
                  }
                }

                final hasTakenToday = r.takenDates.any(
                  (d) =>
                      d.year == now.year &&
                      d.month == now.month &&
                      d.day == now.day,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(r.name),
                    subtitle: Text(
                      'Horas : ${r.times.join(', ')}\nInicio  : ${DateFormat('dd/MM/yyyy').format(r.startDate.toLocal())}\nFin      : ${DateFormat('dd/MM/yyyy').format(r.endDate!.toLocal())}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isWithinTakeWindow && !hasTakenToday)
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await prov.markTaken(r.id, DateTime.now());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Toma registrada ✅'),
                                ),
                              );
                            },
                          ),
                        if (!r.immutable)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openReminderDialog(reminder: r),
                          ),
                        if (!r.immutable)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async =>
                                await prov.deleteReminder(r.id),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openReminderDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
