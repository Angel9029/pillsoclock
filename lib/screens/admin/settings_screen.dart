// ...existing code...
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController =
      TextEditingController(); // para confirmar eliminación

  bool _loading = true;
  bool _saving = false;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? user.displayName ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
      } else {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _db.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      // Optionally update Firebase Auth displayName/email locally
      await user.updateDisplayName(_nameController.text.trim());
      if (_emailController.text.trim() != user.email) {
        try {
          await (user as dynamic).updateEmail(_emailController.text.trim());
        } catch (_) {
          // ignore: avoid_print
          print('Failed to update auth email');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  Future<void> _deleteAccount() async {
    final user = _user;
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

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
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
        title: const Text('Ajustes del administrador'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00A896), Color(0xFF00796B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil superior mejorado
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar: muestra un icono que indica administrador cuando no hay photoURL
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.teal.shade300,
                    backgroundImage:
                        (_user?.photoURL != null) ? NetworkImage(_user!.photoURL!) : null,
                    child: (_user?.photoURL == null)
                        ? const Icon(
                            Icons.admin_panel_settings,
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
                          _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'Administrador',
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
                          label: const Text('Administrador'),
                          backgroundColor: Colors.teal.shade50,
                          avatar: const Icon(Icons.shield, size: 16, color: Colors.teal),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Formulario de perfil con estilo más limpio
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Perfil',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextFormField(
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
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final email = v.trim();
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _updateProfile,
                            icon: const Icon(Icons.save),
                            label: _saving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar cambios'),
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
// ...existing code...