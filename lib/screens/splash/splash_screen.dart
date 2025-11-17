import 'package:flutter/material.dart';
import 'package:pillsoclock/core/services/permission_service.dart';
import 'package:pillsoclock/screens/auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Intentar asegurar permisos (no bloquear): si el usuario los concede, genial; si no, seguimos.
    try {
      await PermissionService.ensureEssentialPermissions(context);
    } catch (_) {
      // ignorar errores de permisos para no bloquear splash
    }

    // Espera corta para que el splash no desaparezca instantáneamente
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
