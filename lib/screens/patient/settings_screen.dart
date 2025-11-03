import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _hasPendingRequest = false; // 👈 control del estado

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPendingRequest(); // 👈 verificamos al iniciar
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _nameCtrl.text = doc['name'] ?? '';
      _emailCtrl.text = doc['email'] ?? '';
    }
  }

  Future<void> _checkPendingRequest() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _db
        .collection('requests')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      _hasPendingRequest = snapshot.docs.isNotEmpty;
    });
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.collection('users').doc(user.uid).update({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Datos actualizados')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db.collection('users').doc(uid).delete();
        await _auth.logout();
      }
    }
  }

  Future<void> _requestRoleUpgrade() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('users').doc(user.uid).get();
    final userData = doc.data() ?? {};

    await _db.collection('requests').add({
      'userId': user.uid,
      'type': 'role_upgrade',
      'status': 'pending',
      'userName': userData['name'] ?? 'Desconocido',
      'userEmail': userData['email'] ?? user.email ?? '',
      'created_at': DateTime.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Solicitud enviada')));

    setState(() {
      _hasPendingRequest = true; // 👈 deshabilita el botón
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateUser,
                      child: const Text('Guardar cambios'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Eliminar cuenta'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _hasPendingRequest
                          ? null
                          : _requestRoleUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasPendingRequest
                            ? Colors.grey
                            : null,
                      ),
                      child: Text(
                        _hasPendingRequest
                            ? 'Solicitud pendiente'
                            : 'Solicitar ser médico',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _auth.logout,
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
