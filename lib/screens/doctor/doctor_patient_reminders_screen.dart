import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../core/services/notification_service.dart';

class DoctorPatientRemindersScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;
  final String patientName;

  const DoctorPatientRemindersScreen({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientRemindersScreen> createState() =>
      _DoctorPatientRemindersScreenState();
}

class _DoctorPatientRemindersScreenState
    extends State<DoctorPatientRemindersScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ReminderProvider>(context);

    if (!_started) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prov.startForUser(widget.patientId);
      });
      _started = true;
    }

    void openProgressModal(ReminderModel r) {
      final progress = prov.computeProgress(r);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Progreso de "${r.name}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 10),
              Text('${(progress * 100).toStringAsFixed(0)}% completado'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }

    void openReminderDialog({ReminderModel? reminder}) {
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
                                setState(
                                  () => startDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    t.hour,
                                    t.minute,
                                  ),
                                );
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
                      final newId = await prov.addReminder(
                        ReminderModel(
                          id: '',
                          userId: widget.patientId,
                          doctorId: widget.doctorId,
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          times: times,
                          startDate: startDate,
                          endDate: endDate,
                          takenDates: [],
                          immutable: true,
                        ),
                      );
                      // opcional: reprogramar notifs localmente para el doctor
                      await NotificationService.cancelNotificationsByPrefix(newId);
                      for (int i = 0; i < times.length; i++) {
                        final parts = times[i].split(':');
                        if (parts.length != 2) continue;
                        final hour = int.tryParse(parts[0]) ?? 0;
                        final minute = int.tryParse(parts[1]) ?? 0;
                        await NotificationService.scheduleDailyNotification(
                          id: '${newId}_$i'.hashCode,
                          title: 'Recordatorio (paciente): ${nameCtrl.text}',
                          body: descCtrl.text.isNotEmpty ? descCtrl.text : 'Recordatorio creado por doctor',
                          hour: hour,
                          minute: minute,
                          payload: newId,
                        );
                      }
                    } else {
                      await prov.updateReminder(
                        reminder.copyWith(
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          times: times,
                          startDate: startDate,
                          endDate: endDate,
                        ),
                      );
                      // reprogramar localmente para consistencia del doctor
                      await NotificationService.cancelNotificationsByPrefix(reminder.id);
                      for (int i = 0; i < times.length; i++) {
                        final parts = times[i].split(':');
                        if (parts.length != 2) continue;
                        final hour = int.tryParse(parts[0]) ?? 0;
                        final minute = int.tryParse(parts[1]) ?? 0;
                        await NotificationService.scheduleDailyNotification(
                          id: '${reminder.id}_$i'.hashCode,
                          title: 'Recordatorio (paciente): ${nameCtrl.text}',
                          body: descCtrl.text.isNotEmpty ? descCtrl.text : 'Recordatorio creado por doctor',
                          hour: hour,
                          minute: minute,
                          payload: reminder.id,
                        );
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
      appBar: AppBar(title: Text('Recordatorios de ${widget.patientName}')),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.reminders.isEmpty
          ? const Center(child: Text('No hay recordatorios.'))
          : ListView.builder(
              itemCount: prov.reminders.length,
              itemBuilder: (ctx, i) {
                final r = prov.reminders[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(r.name),
                    subtitle: Text(
                      'Horas: ${r.times.join(', ')}\nInicio: ${DateFormat('dd/MM/yyyy').format(r.startDate)}\nFin: ${r.endDate != null ? DateFormat('dd/MM/yyyy').format(r.endDate!) : "-"}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.show_chart,
                            color: Colors.orange,
                          ),
                          onPressed: () => openProgressModal(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => openReminderDialog(reminder: r),
                        ),
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
        onPressed: () => openReminderDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
