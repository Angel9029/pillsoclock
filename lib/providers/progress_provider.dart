import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class ProgressProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, double> _progressCache = {};

  double getProgress(String reminderId) => _progressCache[reminderId] ?? 0.0;

  /// 🔹 Recalcula y guarda progreso localmente
  Future<void> refreshProgress(String reminderId) async {
    final value = await computeProgressFromFirestore(reminderId);
    _progressCache[reminderId] = value;
    notifyListeners();
  }

  /// 🔹 Calcula progreso en base a las fechas de inicio, fin y tomas reales
  Future<double> computeProgressFromFirestore(String reminderId) async {
    final doc = await _db.collection('reminders').doc(reminderId).get();
    if (!doc.exists) return 0.0;

    final reminder = ReminderModel.fromFirestore(doc);

    // 🔹 Validar fechas
    final start = reminder.startDate;
    final end = reminder.endDate ?? DateTime.now();
    if (end.isBefore(start)) return 0.0;

    // 🔹 Tomar y limpiar fechas de tomas
    final takenDates = reminder.takenDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();

    if (takenDates.isEmpty) return 0.0;

    // 🔹 Total esperado: días activos * tomas por día
    final totalDays = end.difference(start).inDays + 1;
    final totalExpected = totalDays * reminder.times.length;

    final totalTaken = reminder.takenDates.length;

    final progress = (totalTaken / totalExpected).clamp(0.0, 1.0);
    _progressCache[reminderId] = progress;
    return progress;
  }

  /// 🔹 Cálculo estimado (si no hay datos de Firestore)
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
