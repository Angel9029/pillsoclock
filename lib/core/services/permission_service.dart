import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class PermissionService {
  static Future<void> ensureEssentialPermissions(BuildContext context) async {
    final permissions = <Permission>[
      Permission.notification,
      if (Platform.isAndroid) Permission.ignoreBatteryOptimizations,
    ];

    final results = await permissions.request();

    final denied = results.entries
        .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
        .toList();

    if (denied.isNotEmpty) {
      await _showPermissionDialog(context);
      return;
    }

    if (Platform.isAndroid) {
      await _checkExactAlarmPermission(context);
    }
  }

  /// 🔹 En Android 12+ el permiso de exact alarms debe activarse manualmente
  static Future<void> _checkExactAlarmPermission(BuildContext context) async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      debugPrint('No se pudo abrir ajustes de alarmas exactas: $e');
    }
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Permisos requeridos'),
        content: const Text(
          'Esta app necesita permisos de notificación y alarmas para funcionar correctamente.\n\n'
          'Por favor, actívalos en Ajustes o no podrá continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
          TextButton(onPressed: () => exit(0), child: const Text('Cerrar app')),
        ],
      ),
    );
  }
}
