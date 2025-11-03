import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class ReminderProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ReminderModel> reminders = [];
  bool loading = false;

  /// 🔹 Carga los recordatorios del usuario actual
  Future<void> start(String userId) async {
    loading = true;
    notifyListeners();

    final query = await _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    reminders = query.docs
        .map((doc) => ReminderModel.fromFirestore(doc))
        .toList();

    loading = false;
    notifyListeners();
  }

  /// 🔹 Agrega un nuevo recordatorio
  Future<void> addReminder({
    required String name,
    required String description,
    required List<String> times,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = FirebaseFirestore.instance.app.options.projectId ?? 'demo';

    final newDoc = await _db.collection('reminders').add({
      'userId': userId,
      'name': name,
      'description': description,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'takenDates': [],
      'immutable': false,
    });

    final newReminder = ReminderModel(
      id: newDoc.id,
      userId: userId,
      name: name,
      description: description,
      times: times,
      startDate: startDate,
      endDate: endDate,
      takenDates: [],
    );

    reminders.add(newReminder);
    notifyListeners();
  }

  /// 🔹 Actualiza un recordatorio existente
  Future<void> updateReminder(String id, Map<String, dynamic> data) async {
    await _db.collection('reminders').doc(id).update({
      'name': data['name'],
      'description': data['description'],
      'times': data['times'],
      'startDate': Timestamp.fromDate(data['startDate']),
      'endDate': Timestamp.fromDate(data['endDate']),
    });

    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index] = ReminderModel(
        id: reminders[index].id,
        userId: reminders[index].userId,
        name: data['name'],
        description: data['description'],
        times: List<String>.from(data['times']),
        startDate: data['startDate'],
        endDate: data['endDate'],
        takenDates: reminders[index].takenDates,
      );
      notifyListeners();
    }
  }

  /// 🔹 Marca una toma como realizada
  Future<void> markTaken(String id, DateTime date) async {
    final docRef = _db.collection('reminders').doc(id);
    await docRef.update({
      'takenDates': FieldValue.arrayUnion([Timestamp.fromDate(date)]),
    });

    // 🟢 Actualiza localmente
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index].takenDates.add(date);
      notifyListeners();
    }
  }

  /// 🔹 Elimina un recordatorio
  Future<void> deleteReminder(String id) async {
    await _db.collection('reminders').doc(id).delete();
    reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
