import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/progress_card.dart';

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

    // 🔹 Filtrar: solo recordatorios creados por ESTE doctor
    final myReminders = prov.reminders
        .where((r) => r.doctorId == widget.doctorId)
        .toList();

    void openProgressModal(ReminderModel r) {
      final progress = prov.computeProgress(r);
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Progreso: ${r.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.teal.withOpacity(0.15),
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% completado',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tomas registradas: ${r.takenDates.length}', style: const TextStyle(fontSize: 14)),
                      Text('Horas: ${r.times.join(", ")}', style: const TextStyle(fontSize: 14)),
                      Text('Inicio: ${DateFormat('dd/MM/yyyy').format(r.startDate)}', style: const TextStyle(fontSize: 14)),
                      if (r.endDate != null)
                        Text('Fin: ${DateFormat('dd/MM/yyyy').format(r.endDate!)}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void openReminderDialog({ReminderModel? reminder}) {
      final nameCtrl = TextEditingController(text: reminder?.name ?? '');
      final descCtrl = TextEditingController(text: reminder?.description ?? '');
      final timesCtrl = TextEditingController(
        text: reminder?.times.join(', ') ?? '',
      );
      DateTime startDate =
          reminder?.startDate ?? DateTime.now().add(const Duration(minutes: 1));
      DateTime endDate =
          reminder?.endDate ?? DateTime.now().add(const Duration(days: 30));
      String? timeError;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            bool validateTimes(String input) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del medicamento',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Horas (ej: 08:00, 20:00)',
                        errorText: timeError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setState(() {
                          timeError = validateTimes(val) ? null : 'Formato inválido. Usa HH:MM separadas por comas';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Inicio: ${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}',
                            style: const TextStyle(fontSize: 14),
                          ),
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
                        Expanded(
                          child: Text(
                            'Fin: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                            style: const TextStyle(fontSize: 14),
                          ),
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
                    if (timeError != null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('❌ Revisa el formato de horas')),
                      );
                      return;
                    }
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('❌ Ingresa un nombre')),
                      );
                      return;
                    }
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
                      // ✅ Programar notificaciones para el PACIENTE
                      await NotificationService.cancelNotificationsByPrefix(newId);
                      for (int i = 0; i < times.length; i++) {
                        final parts = times[i].split(':');
                        if (parts.length != 2) continue;
                        final hour = int.tryParse(parts[0]) ?? 0;
                        final minute = int.tryParse(parts[1]) ?? 0;
                        await NotificationService.scheduleDailyNotification(
                          id: '${newId}_$i'.hashCode,
                          title: 'Recordatorio: ${nameCtrl.text}',
                          body: descCtrl.text.isNotEmpty ? descCtrl.text : 'Es hora de tu medicamento',
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
                      // ✅ Reprogramar notificaciones para el PACIENTE
                      await NotificationService.cancelNotificationsByPrefix(reminder.id);
                      for (int i = 0; i < times.length; i++) {
                        final parts = times[i].split(':');
                        if (parts.length != 2) continue;
                        final hour = int.tryParse(parts[0]) ?? 0;
                        final minute = int.tryParse(parts[1]) ?? 0;
                        await NotificationService.scheduleDailyNotification(
                          id: '${reminder.id}_$i'.hashCode,
                          title: 'Recordatorio: ${nameCtrl.text}',
                          body: descCtrl.text.isNotEmpty ? descCtrl.text : 'Es hora de tu medicamento',
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
      appBar: AppBar(
        title: Text('Medicamentos: ${widget.patientName}'),
        elevation: 0,
        centerTitle: true,
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : myReminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay recordatorios creados por ti',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: myReminders.length,
                  itemBuilder: (ctx, i) {
                    final r = myReminders[i];
                    final progress = prov.computeProgress(r);

                    return ProgressCard(
                      reminderId: r.id,
                      name: r.name,
                      description: r.description,
                      times: r.times,
                      startDate: r.startDate,
                      endDate: r.endDate,
                      progress: progress,
                      takenDatesLenght: r.takenDates.length,
                    ).withActions(
                      onEdit: () => openReminderDialog(reminder: r),
                      onDelete: () async => await prov.deleteReminder(r.id),
                      onProgress: () => openProgressModal(r),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openReminderDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo'),
      ),
    );
  }
}
