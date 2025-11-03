import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _users = [];
  bool _loading = false;
  bool _hasMore = true;
  final int _perPage = 50;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (_loading) return;

    setState(() => _loading = true);

    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isNotEqualTo: 'admin')
        .orderBy('name')
        .limit(_perPage);

    if (_lastDocument != null && !reset) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (reset) {
      _users = snapshot.docs;
    } else {
      _users.addAll(snapshot.docs);
    }

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    }

    if (snapshot.docs.length < _perPage) {
      _hasMore = false;
    }

    setState(() => _loading = false);
  }

  void _onSearchChanged() {
    // Si quieres hacer búsqueda en Firestore, aquí puedes disparar query por nombre/email/rol
    // Por simplicidad aquí filtramos localmente
    setState(() {});
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final text = _searchController.text.toLowerCase();
    if (text.isEmpty) return true;

    final name = (data['name'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();
    final role = (data['role'] ?? '').toString().toLowerCase();

    return name.contains(text) || email.contains(text) || role.contains(text);
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers =
        _users.where((doc) => doc.id != currentUser?.uid && _matchesFilter(doc.data() as Map<String, dynamic>)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, correo o rol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _onSearchChanged(),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!_loading &&
                    _hasMore &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _loadUsers();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: filteredUsers.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredUsers.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final user = filteredUsers[index];
                  final data = user.data() as Map<String, dynamic>;
                  final role = data['role'] ?? 'paciente';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(data['name'] ?? 'Sin nombre'),
                      subtitle: Text('${data['email'] ?? ''} • $role'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar usuario'),
                              content: const Text(
                                  '¿Estás seguro de eliminar este usuario? Esta acción no se puede deshacer.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.id)
                                .delete();
                            setState(() {
                              _users.remove(user);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Usuario eliminado correctamente')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}