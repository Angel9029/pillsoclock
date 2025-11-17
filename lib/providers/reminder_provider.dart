import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import '../core/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderProvider with ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<ReminderModel> reminders = [];
  bool loading = true;
  StreamSubscription? _sub;

  // 🔹 Pacientes: stream de sus propios recordatorios
  void startForUser(String userId) {
    loading = true;
    notifyListeners();
    _sub = _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snap) async {
          reminders = snap.docs
              .map((d) => ReminderModel.fromFirestore(d))
              .toList();

          // ✅ Programar notificaciones locales para cada reminder (cliente paciente)
          for (var r in reminders) {
            try {
              await NotificationService.cancelNotificationsByPrefix(r.id);
            } catch (_) {}
            for (int i = 0; i < r.times.length; i++) {
              final parts = r.times[i].split(':');
              if (parts.length != 2) continue;
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;
              // id único por reminder+hora
              final notifId = '${r.id}_$i'.hashCode;
              await NotificationService.scheduleDailyNotification(
                id: notifId,
                title: 'Recordatorio: ${r.name}',
                body: r.description.isNotEmpty ? r.description : 'Es hora de tu dosis',
                hour: hour,
                minute: minute,
                payload: r.id,
              );
            }
          }

          loading = false;
          notifyListeners();
        });
  }

  // 🔹 Doctor: stream de recordatorios creados por este doctor
  void startForDoctor(String doctorId) {
    loading = true;
    notifyListeners();
    _sub = _db
        .collection('reminders')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .listen((snap) {
          reminders = snap.docs
              .map((d) => ReminderModel.fromFirestore(d))
              .toList();
          loading = false;
          notifyListeners();
        });
  }

  void stop() {
    _sub?.cancel();
  }

  Future<String> addReminder(ReminderModel reminder) async {
    final ref = await _db.collection('reminders').add({
      ...reminder.toFirestore(),
      'doctorId': reminder.doctorId,
      'immutable': reminder.immutable,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    if (reminder.immutable) return;
    await _db
        .collection('reminders')
        .doc(reminder.id)
        .update(reminder.toFirestore());
  }

  Future<void> deleteReminder(String id, {bool immutable = false}) async {
    if (immutable) return;
    await _db.collection('reminders').doc(id).delete();
  }

  /// ✅ Marca un recordatorio como tomado hoy y actualiza lista local
  Future<void> markTaken(String reminderId) async {
    final docRef = _db.collection('reminders').doc(reminderId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final r = ReminderModel.fromFirestore(doc);
    final updatedTakenDates = [...r.takenDates, DateTime.now()];

    // Actualiza en Firestore
    await docRef.update({
      'takenDates': updatedTakenDates
          .map((d) => Timestamp.fromDate(d))
          .toList(),
    });

    // 🔹 Actualiza la lista local (para refrescar UI al instante)
    final index = reminders.indexWhere((rem) => rem.id == reminderId);
    if (index != -1) {
      reminders[index] = r.copyWith(takenDates: updatedTakenDates);
      notifyListeners();
    }
  }

  double computeProgress(ReminderModel reminder) {
    final total =
        reminder.times.length *
        ((reminder.endDate ?? DateTime.now())
                .difference(reminder.startDate)
                .inDays +
            1);
    if (total == 0) return 1.0;
    return (reminder.takenDates.length / total).clamp(0.0, 1.0);
  }
}

// 🔹 Extensión para guardar en Firestore
extension on ReminderModel {
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'doctorId': doctorId,
    'name': name,
    'description': description,
    'times': times,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'takenDates': takenDates.map((d) => Timestamp.fromDate(d)).toList(),
    'immutable': immutable,
  };
}
