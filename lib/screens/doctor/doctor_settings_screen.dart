import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController =
      TextEditingController(); // para confirmar eliminación
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
      } else {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para eliminar tu cuenta, ingresa tu contraseña para confirmar.',
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Ajustes del doctor'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // distinto esquema de color para doctor
              colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil superior mejorado con icono de médico
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue.shade300,
                    backgroundImage:
                        (_auth.currentUser?.photoURL != null) ? NetworkImage(_auth.currentUser!.photoURL!) : null,
                    child: (_auth.currentUser?.photoURL == null)
                        ? const Icon(
                            Icons.medical_services,
                            size: 36,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : 'Doctor',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _emailController.text,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: const Text('Doctor'),
                          backgroundColor: Colors.blue.shade50,
                          avatar: const Icon(Icons.local_hospital, size: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Formulario de perfil con estilo más limpio (sin cambiar funcionalidad)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Perfil',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade50
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade50
                          : Colors.grey.shade800,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar cambios'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Acciones peligrosas con diseño más claro
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones peligrosas',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Eliminar tu cuenta borrará todos los datos asociados. Esta acción no se puede deshacer.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar cuenta permanentemente'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}