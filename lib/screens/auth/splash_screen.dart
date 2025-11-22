import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    try {
      // intenta inicializar Firebase solo si no está inicializado
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // ignore errors aquí; la app seguirá mostrando el splash
    }

    // espera mínimo para que el usuario vea la imagen (ajusta duración si quieres)
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // degradado entre lilas suaves y verde-agua claro
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFD1C4E9), // lilac claro
        Color(0xFFB2EBF2), // verde-agua claro
      ],
    );

    // colores auxiliares para detalles
    const accentLilac = Color(0xFF8E7CC3);
    const accentAqua = Color(0xFF3FBFB0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // imagen de splash (usa el asset existente)
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Image.asset(
                    'assets/carga1.gif',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, st) => const Icon(
                      Icons.local_hospital_rounded,
                      size: 120,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Pills O'Clock",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // barra de progreso con acento que combina lilac/agua
                SizedBox(
                  height: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 140,
                        child: LinearProgressIndicator(
                          backgroundColor: Color(0x44FFFFFF),
                          valueColor: AlwaysStoppedAnimation<Color>(accentAqua),
                        ),
                      ),
                      SizedBox(width: 12),
                      CircularProgressIndicator(strokeWidth: 2, color: accentLilac),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
