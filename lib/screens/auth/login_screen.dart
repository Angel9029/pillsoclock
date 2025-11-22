// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // actualiza la UI en cada cambio para mostrar validación en tiempo real
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isEmailValid() {
    final value = _email.text.trim();
    if (value.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(value);
  }

  bool _isPasswordValid() {
    final v = _password.text.trim();
    return v.length >= 6;
  }

  Future<void> _submit() async {
    // Form validator seguirá ejecutándose; adicionalmente se fuerza validación visual
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProviderLocal>();
    final err = await auth.login(email: _email.text.trim(), password: _password.text.trim());
    if (err != null) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _loading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // combinación azul claro -> lila claro
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB3E5FC), Color(0xFFD1C4E9)],
    );

    final titleColor = const Color(0xFF1E3A8A); // azul oscuro para contraste
    final accentLilac = const Color(0xFFD6C6F1); // botón lila claro
    final inputFill = Colors.white.withOpacity(0.06);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera con imagen en lugar de icono
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 150,
                            child: Image.asset(
                              'assets/icon1.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.local_hospital_rounded,
                                size: 120,
                                color: titleColor.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Pills O'Clock",
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 35,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Controla tus medicamentos de forma simple y segura',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleColor.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Formulario integrado
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        // valida continuamente para mostrar mensajes en tiempo real
                        autovalidateMode: AutovalidateMode.always,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Correo',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: inputFill,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: _email.text.isEmpty
                                    ? null
                                    : (_isEmailValid()
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.error, color: Colors.redAccent)),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Ingresa tu correo';
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value)) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                filled: true,
                                fillColor: inputFill,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: _password.text.isEmpty
                                    ? null
                                    : (_isPasswordValid()
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.error, color: Colors.redAccent)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña';
                                if (v.trim().length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: _loading
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                  : ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentLilac,
                                        foregroundColor: titleColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 4,
                                      ),
                                      child: const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Crear cuenta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text(
                            'Crear cuenta',
                            style: TextStyle(color: titleColor.withOpacity(0.95), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}