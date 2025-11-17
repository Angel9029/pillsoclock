import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

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
        .listen((snap) {
          reminders = snap.docs
              .map((d) => ReminderModel.fromFirestore(d))
              .toList();
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

  Future<void> addReminder(ReminderModel reminder) async {
    await _db.collection('reminders').add({
      ...reminder.toFirestore(),
      'doctorId': reminder.doctorId,
      'immutable': reminder.immutable,
    });
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
