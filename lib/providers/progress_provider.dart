import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class ProgressProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Calcula progreso en base a las fechas de inicio, fin y tomas reales
  Future<double> computeProgressFromFirestore(String reminderId) async {
    final doc = await _db.collection('reminders').doc(reminderId).get();
    if (!doc.exists) return 0.0;

    final reminder = ReminderModel.fromFirestore(doc);

    if (reminder.takenDates.isEmpty) return 0.0;

    // Total esperado (días * veces por día)
    final totalDays = reminder.endDate != null
        ? reminder.endDate!.difference(reminder.startDate).inDays + 1
        : 30;
    final totalExpected = totalDays * reminder.times.length;

    final totalTaken = reminder.takenDates.length;

    return (totalTaken / totalExpected).clamp(0.0, 1.0);
  }

  /// 🔹 Cálculo estimado simple (si no hay datos de Firestore)
  Future<double> computeProgress(ReminderModel reminder) async {
    final start = reminder.startDate;
    final end =
        reminder.endDate ?? DateTime.now().add(const Duration(days: 30));
    final now = DateTime.now();

    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;

    final total = end.difference(start).inHours;
    final elapsed = now.difference(start).inHours;

    return (elapsed / total).clamp(0.0, 1.0);
  }
}
