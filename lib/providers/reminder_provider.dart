import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import '../core/services/notification_service.dart';
import '../core/services/auth_service.dart';

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
    // Construir mapa limpio y serializable
    final data = {
      'userId': reminder.userId,
      'doctorId': reminder.doctorId,
      'name': reminder.name,
      'description': reminder.description,
      'times': reminder.times.map((e) => e.toString()).toList(),
      'startDate': Timestamp.fromDate(reminder.startDate),
      'endDate': reminder.endDate != null ? Timestamp.fromDate(reminder.endDate!) : null,
      'takenDates': <Timestamp>[],
      'immutable': (reminder.immutable == true),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = await _db.collection('reminders').add(data);
    return ref.id;
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    // Verificamos en Firestore si el reminder es inmutable y quién lo creó
    final docRef = _db.collection('reminders').doc(reminder.id);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final bool isImmutable = data['immutable'] == true;
    final String? doctorId = data['doctorId'] as String?;
    final String? currentUid = AuthService().currentUser?.uid;

    // Si es inmutable y el usuario actual NO es el doctor creador, no permitir edición
    if (isImmutable && (currentUid == null || currentUid != doctorId)) {
      return;
    }

    final updates = {
      'name': reminder.name,
      'description': reminder.description,
      'times': reminder.times.map((e) => e.toString()).toList(),
      'startDate': Timestamp.fromDate(reminder.startDate),
      'endDate': reminder.endDate != null ? Timestamp.fromDate(reminder.endDate!) : null,
    };

    await docRef.update(updates);
  }

  Future<void> deleteReminder(String id, {bool immutable = false}) async {
    // Consultar documento y autorización actual
    final docRef = _db.collection('reminders').doc(id);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final bool isImmutable = data['immutable'] == true;
    final String? doctorId = data['doctorId'] as String?;
    final String? currentUid = AuthService().currentUser?.uid;

    // Si es inmutable y el usuario actual NO es el doctor creador, no permitir eliminación
    if (isImmutable && (currentUid == null || currentUid != doctorId)) {
      return;
    }

    await docRef.delete();
    // Cancelar notificaciones locales asociadas
    await NotificationService.cancelNotificationsByPrefix(id);
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
    final start = reminder.startDate;
    final end = reminder.endDate ?? DateTime.now();
    
    // 🔹 Calcular días activos (inclusive)
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) return 0.0;
    
    // 🔹 Total esperado: días × tomas por día
    final timesPerDay = reminder.times.length;
    final totalExpected = totalDays * timesPerDay;
    
    if (totalExpected == 0) return 1.0;
    
    // 🔹 Progreso = tomas reales / tomas esperadas
    return (reminder.takenDates.length / totalExpected).clamp(0.0, 1.0);
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
