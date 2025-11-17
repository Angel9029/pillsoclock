import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class PermissionService {
  static Future<void> ensureEssentialPermissions(BuildContext context) async {
    // Solo solicitar permiso de notificaciones de runtime.
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final res = await Permission.notification.request();
      if (res.isPermanentlyDenied) {
        // Mostrar diálogo informativo (no forzar cierre)
        await _showPermissionDialog(context);
      }
    }

    // Para Android: sugerir (no forzar) revisar ajustes de alarmas exactas si es necesario.
    if (Platform.isAndroid) {
      await _checkExactAlarmPermissionIfNeeded();
    }
  }

  /// 🔹 En Android 12+ el permiso de exact alarms debe activarse manualmente
  static Future<void> _checkExactAlarmPermissionIfNeeded() async {
    // No abrimos ajustes automáticamente. Solo intentamos abrir si la plataforma lo admite.
    // Esto evita molestar al usuario en cada splash.
    return;
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    // Diálogo informativo; puede cerrarse para seguir usando la app.
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Permisos recomendados'),
        content: const Text(
          'Para recibir recordatorios como notificaciones, activa los permisos de notificaciones en Ajustes.\n\n'
          'Si prefieres, puedes continuar sin ellos.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
