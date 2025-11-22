// lib/core/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';

class ReminderService {
  final _db = FirebaseFirestore.instance;

  /// 🔹 Escucha los recordatorios de un usuario autenticado
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamRemindersForUser(String userId) {
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// 🔹 Crea un nuevo recordatorio y programa sus notificaciones
  Future<void> createReminder({
    required String userId,
    String? doctorId,
    required String name,
    required String description,
    required List<String> times,
    required DateTime startDate,
    DateTime? endDate,
    bool immutable = false,
  }) async {
    final docRef = await _db.collection('reminders').add({
      'userId': userId,
      'doctorId': doctorId,
      'name': name,
      'description': description,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'takenDates': <Timestamp>[],
      'immutable': immutable,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Programa notificaciones locales
    await _scheduleReminderNotifications(
      docRef.id,
      name,
      description,
      times,
      startDate,
    );
  }

  /// 🔹 Programa las notificaciones diarias (ignora horas pasadas para hoy)
  Future<void> _scheduleReminderNotifications(
    String reminderId,
    String title,
    String description,
    List<String> times,
    DateTime startDate,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);

    int baseId = reminderId.hashCode & 0x7fffffff; // ID base único

    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        today.year,
        today.month,
        today.day,
        hour,
        minute,
      );

      // 👇 Si la hora ya pasó, agenda para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await NotificationService.scheduleDailyNotification(
        id: baseId + i,
        title: title,
        body: description,
        hour: hour,
        minute: minute,
        payload: reminderId,
      );
    }
  }

  /// 🔹 Actualiza un recordatorio existente
  Future<void> updateReminder(String id, Map<String, dynamic> updates) async {
    await _db.collection('reminders').doc(id).update(updates);

    // Si cambian las horas, reprograma notificaciones
    if (updates.containsKey('times') || updates.containsKey('startDate')) {
      final reminder = await _db.collection('reminders').doc(id).get();
      if (!reminder.exists) return;

      final data = reminder.data()!;
      final name = data['name'] ?? 'Recordatorio';
      final desc = data['description'] ?? '';
      final times = List<String>.from(data['times'] ?? []);
      DateTime startDate;
      final sd = data['startDate'];
      if (sd is Timestamp) {
        startDate = sd.toDate();
      } else if (sd is String) {
        startDate = DateTime.tryParse(sd) ?? DateTime.now();
      } else {
        startDate = DateTime.now();
      }

      // Cancela solo notificaciones asociadas a este reminder y reprograma
      await NotificationService.cancelNotificationsByPrefix(id);
      await _scheduleReminderNotifications(id, name, desc, times, startDate);
    }
  }

  /// 🔹 Elimina un recordatorio y sus notificaciones
  Future<void> deleteReminder(String id) async {
    await _db.collection('reminders').doc(id).delete();

    // Cancela todas las notificaciones locales relacionadas
    await NotificationService.cancelNotificationsByPrefix(id);
  }
}
