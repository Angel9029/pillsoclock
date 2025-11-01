import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // para confirmar eliminación
  bool _loading = true;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Confirmación por diálogo
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Para eliminar tu cuenta, ingresa tu contraseña para confirmar.'),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final cred = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes del administrador')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Perfil',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration:
                const InputDecoration(labelText: 'Correo electrónico'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _updateProfile,
            icon: const Icon(Icons.save),
            label: const Text('Guardar cambios'),
          ),
          const SizedBox(height: 24),

          // Logout
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Sección de acciones peligrosas
          Text(
            'Acciones peligrosas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar cuenta permanentemente'),
          ),
        ],
      ),
    );
  }
}