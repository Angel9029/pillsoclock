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
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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

    // success — AuthProvider will update and AuthWrapper navigates
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_hospital_rounded, size: 68, color: Colors.teal),
                    const SizedBox(height: 12),
                    const Text('Pills O\'Clock', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Control de toma de medicamentos', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 18),
                    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 12),
                    TextField(controller: _password, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)), obscureText: true),
                    const SizedBox(height: 18),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.login), label: const Text('Iniciar sesión')),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Crear cuenta')),
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