import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;
  bool _requested = false;
  bool _loading = false;

  Future<void> _sendRequest() async {
    setState(() => _loading = true);
    final email = _auth.currentUser!.email!;
    await _firestoreService.createRoleRequest(email);
    setState(() {
      _requested = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Text(user.email![0].toUpperCase())),
            const SizedBox(height: 16),
            Text(user.email!, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            _requested
                ? const Text("Solicitud enviada. Espera aprobación del administrador.")
                : ElevatedButton(
                    onPressed: _loading ? null : _sendRequest,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Solicitar rol de médico'),
                  ),
          ],
        ),
      ),
    );
  }
}