import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProviderLocal>();
    return Scaffold(
      appBar: AppBar(title: const Text('Médico')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.medical_services_rounded, size: 72, color: Colors.teal),
          const SizedBox(height: 12),
          const Text('Panel Médico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          )
        ]),
      ),
    );
  }
}