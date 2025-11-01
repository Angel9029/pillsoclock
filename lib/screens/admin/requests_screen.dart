import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  Future<void> _updateRequestStatus(
      String requestId, String userId, String status) async {
    final db = FirebaseFirestore.instance;

    await db.collection('requests').doc(requestId).update({'status': status});

    if (status == 'accepted') {
      await db.collection('users').doc(userId).update({'role': 'doctor'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de médicos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar solicitudes'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay solicitudes pendientes.'));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final data = req.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['userName'] ?? 'Usuario desconocido'),
                  subtitle: Text(data['userEmail'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () =>
                            _updateRequestStatus(req.id, data['userId'], 'rejected'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateRequestStatus(req.id, data['userId'], 'accepted'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}