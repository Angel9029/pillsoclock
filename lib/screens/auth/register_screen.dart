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
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 12),
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
                          : ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.person_add), label: const Text('Crear cuenta')),
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