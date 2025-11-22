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
  bool _hasPendingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPendingRequest();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _nameCtrl.text = doc['name'] ?? '';
      _emailCtrl.text = doc['email'] ?? '';
    } else {
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
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
    if (mounted) setState(() => _hasPendingRequest = snapshot.docs.isNotEmpty);
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

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Datos actualizados')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Solicitud enviada')));
      setState(() => _hasPendingRequest = true);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Keep patient purple color + person icon as requested
    const gradientColors = [
      Color.fromARGB(255, 121, 40, 161),
      Color.fromARGB(255, 78, 27, 154)
    ];
    final user = _auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Ajustes del paciente'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile card (improved visuals)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.deepPurple.shade400,
                          backgroundImage: (user?.photoURL != null)
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: (user?.photoURL == null)
                              ? Text(
                                  _nameCtrl.text.isNotEmpty
                                      ? _initials(_nameCtrl.text)
                                      : 'P',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text
                                    : 'Paciente',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.email,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _emailCtrl.text,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey.shade700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: const Text('Paciente'),
                                backgroundColor: Colors.purple.shade50,
                                avatar: const Icon(Icons.person,
                                    size: 16, color: Colors.deepPurple),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Profile form card (styling only)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: const Icon(Icons.person),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light
                                  ? Colors.grey.shade50
                                  : Colors.grey.shade800,
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: const Icon(Icons.email),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light
                                  ? Colors.grey.shade50
                                  : Colors.grey.shade800,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _updateUser,
                                  icon: const Icon(Icons.save),
                                  label: _isLoading
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Actions card (styled)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Acciones',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed:
                              _hasPendingRequest ? null : _requestRoleUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _hasPendingRequest ? Colors.grey : null,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_hasPendingRequest
                              ? 'Solicitud pendiente'
                              : 'Solicitar ser médico'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Eliminar cuenta'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _auth.logout,
                          child: const Text('Cerrar sesión'),
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
