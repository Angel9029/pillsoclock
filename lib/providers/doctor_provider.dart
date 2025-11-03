// providers/doctor_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class DoctorProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;

  List<Map<String, dynamic>> _linkedPatients = [];
  List<Map<String, dynamic>> get linkedPatients => _linkedPatients;

  final Map<String, List<ReminderModel>> _patientReminders = {};
  Map<String, List<ReminderModel>> get patientReminders => _patientReminders;

  bool loading = false;

  final String doctorId;
  DoctorProvider({required this.doctorId});

  /// Solicitar vinculación con un paciente
  Future<void> requestLink(String patientId) async {
    final doc = await _db
        .collection('request_patient')
        .where('doctor_id', isEqualTo: doctorId)
        .where('patient_id', isEqualTo: patientId)
        .get();

    if (doc.docs.isEmpty) {
      await _db.collection('request_patient').add({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'status': 'pending',
        'created_at': Timestamp.now(),
      });
    }
  }

  /// Obtener solicitudes pendientes del doctor
  void listenPendingRequests() {
    _db
        .collection('request_patient')
        .where('patient_id', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          _pendingRequests = snapshot.docs
              .map((d) => {...d.data(), 'id': d.id})
              .toList();
          notifyListeners();
        });
  }

  /// Aprobar solicitud de vinculación
  Future<void> acceptRequest(String requestId, String patientId) async {
    await _db.collection('request_patient').doc(requestId).update({
      'status': 'accepted',
    });

    // Crear vínculo en doctor_patients
    await _db.collection('doctor_patients').add({
      'doctor_id': doctorId,
      'patient_id': patientId,
      'linked_at': Timestamp.now(),
    });

    _pendingRequests.removeWhere((r) => r['id'] == requestId);
    notifyListeners();
  }

  /// Rechazar solicitud
  Future<void> rejectRequest(String requestId) async {
    await _db.collection('request_patient').doc(requestId).update({
      'status': 'rejected',
    });
    _pendingRequests.removeWhere((r) => r['id'] == requestId);
    notifyListeners();
  }

  /// Obtener pacientes vinculados
  void listenLinkedPatients() {
    _db
        .collection('doctor_patients')
        .where('doctor_id', isEqualTo: doctorId)
        .snapshots()
        .listen((snapshot) async {
          _linkedPatients = [];
          for (var doc in snapshot.docs) {
            final patientDoc = await _db
                .collection('users')
                .doc(doc['patient_id'])
                .get();
            if (patientDoc.exists) {
              _linkedPatients.add({'id': patientDoc.id, ...patientDoc.data()!});
            }
          }
          notifyListeners();
        });
  }

  /// Obtener recordatorios de un paciente
  void listenPatientReminders(String patientId) {
    _db
        .collection('reminders')
        .where('userId', isEqualTo: patientId)
        .snapshots()
        .listen((snapshot) {
          final reminders = snapshot.docs
              .map((d) => ReminderModel.fromFirestore(d))
              .toList();
          _patientReminders[patientId] = reminders;
          notifyListeners();
        });
  }

  /// Crear recordatorio para un paciente (inmutable)
  Future<void> addReminderForPatient(
    String patientId,
    ReminderModel reminder,
  ) async {
    await _db.collection('reminders').add({
      'userId': patientId,
      'name': reminder.name,
      'description': reminder.description,
      'times': reminder.times,
      'startDate': Timestamp.fromDate(reminder.startDate),
      'endDate': reminder.endDate != null
          ? Timestamp.fromDate(reminder.endDate!)
          : null,
      'takenDates': [],
      'immutable': true,
    });
  }

  /// Actualizar recordatorio (solo doctor)
  Future<void> updateReminder(
    String reminderId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('reminders').doc(reminderId).update(data);
  }

  /// Eliminar recordatorio (solo doctor)
  Future<void> deleteReminder(String reminderId) async {
    await _db.collection('reminders').doc(reminderId).delete();
  }
}
