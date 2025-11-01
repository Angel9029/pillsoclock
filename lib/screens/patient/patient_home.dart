import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProviderLocal>();
    return Scaffold(
      appBar: AppBar(title: const Text('Paciente')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.health_and_safety_rounded, size: 72, color: Colors.teal),
          const SizedBox(height: 12),
          const Text("Bienvenido, paciente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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