// screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // listeners para validación en tiempo real y actualizar UI
    _name.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isNameValid() {
    return _name.text.trim().isNotEmpty;
  }

  bool _isEmailValid() {
    final value = _email.text.trim();
    if (value.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(value);
  }

  bool _isPasswordValid() {
    return _password.text.trim().length >= 6;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProviderLocal>();
    final err = await auth.register(
      email: _email.text.trim(),
      password: _password.text.trim(),
      name: _name.text.trim(),
    );

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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Paleta combinada con login: celeste -> lila claro
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB3E5FC), Color(0xFFD1C4E9)],
    );

    final titleColor = const Color(0xFF1E3A8A);
    const accentLilac = Color(0xFFD6C6F1);
    final inputFill = Colors.white.withOpacity(0.06);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with image
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: Image.asset(
                              'assets/icon1.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.local_hospital_rounded, size: 96, color: titleColor.withOpacity(0.9)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Crear cuenta',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Regístrate para empezar a controlar tu medicación',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: titleColor.withOpacity(0.75), fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.always, // validación en tiempo real
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              decoration: InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: const Icon(Icons.person),
                                filled: true,
                                fillColor: inputFill,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: _name.text.isEmpty
                                    ? null
                                    : (_isNameValid()
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.error, color: Colors.redAccent)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 14),
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
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: _loading
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                  : ElevatedButton.icon(
                                      onPressed: _submit,
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Crear cuenta', style: TextStyle(fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentLilac,
                                        foregroundColor: titleColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 3,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back / already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Ya tienes cuenta?', style: TextStyle(color: titleColor.withOpacity(0.85))),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Iniciar sesión', style: TextStyle(color: titleColor, fontWeight: FontWeight.w700)),
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