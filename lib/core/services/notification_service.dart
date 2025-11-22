// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _instance =
      FlutterLocalNotificationsPlugin();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Callback que la app puede asignar para manejar acciones desde notificaciones
  // recibe payload (String?) y actionId (String?)
  static void Function(String? payload, String? actionId)? onNotificationAction;

  /// Permite registrar el callback más cómodamente
  static void setOnNotificationAction(void Function(String? payload, String? actionId) cb) {
    onNotificationAction = cb;
  }

  /// 🔹 Inicializa notificaciones y zonas horarias
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Lima'));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _instance.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Reenvía a quien haya registrado el callback
        final payload = details.payload;
        final actionId = details.actionId;
        try {
          onNotificationAction?.call(payload, actionId);
        } catch (e) {
          // evitar que la app falle por error en callback
        }
      },
    );
  }

  /// 🔹 Muestra una notificación inmediata
  static Future<void> showImmediate(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction('TAKEN', 'Tomada'),
    ];

    final androidDetails = AndroidNotificationDetails(
      'meditrack_channel',
      'Recordatorios',
      channelDescription: 'Notificaciones de recordatorios de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      actions: actions,
    );

    await _instance.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// 🔹 Programa una notificación diaria, ignorando horas ya pasadas hoy
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 👇 Si la hora ya pasó, programa para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction('TAKEN', 'Tomada'),
    ];

    final androidDetails = AndroidNotificationDetails(
      'meditrack_channel',
      'Recordatorios',
      channelDescription: 'Notificaciones de recordatorios de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      actions: actions,
    );

    await _instance.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 🔁 diario
      payload: payload,
    );
  }

  /// 🔹 Programa una notificación exacta para una fecha específica
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    // Si ya pasó, se mueve al siguiente día
    if (tzDateTime.isBefore(now)) {
      tzDateTime = tzDateTime.add(const Duration(days: 1));
    }

    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction('TAKEN', 'Tomada'),
    ];

    final androidDetails = AndroidNotificationDetails(
      'meditrack_channel',
      'Recordatorios',
      channelDescription: 'Notificaciones de recordatorios de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      actions: actions,
    );

    await _instance.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// 🔹 Cancela una notificación por su ID
  static Future<void> cancel(int id) async {
    await _instance.cancel(id);
  }

  /// 🔹 Cancela todas las notificaciones
  static Future<void> cancelAll() async {
    await _instance.cancelAll();
  }

  /// 🔹 Cancela todas las notificaciones asociadas a un recordatorio (por prefix)
  static Future<void> cancelNotificationsByPrefix(String reminderId) async {
    final pending = await _instance.pendingNotificationRequests();
    for (var n in pending) {
      if (n.payload != null && n.payload!.startsWith(reminderId)) {
        await _instance.cancel(n.id);
      }
    }
  }
}
