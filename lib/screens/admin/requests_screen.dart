import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  Future<void> _updateRequestStatus(
    String requestId,
    String userId,
    String status,
  ) async {
    final db = FirebaseFirestore.instance;

    final requestRef = db.collection('requests').doc(requestId);

    final snapshot = await requestRef.get();
    if (!snapshot.exists) {
      debugPrint('⚠️ La solicitud no existe');
      return;
    }

    await requestRef.update({'status': status});

    // Si es aceptada → actualizar rol del usuario
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  const Text('Error al cargar'),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Sin solicitudes'),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final data = req.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.orange, size: 24),
                  ),
                  title: Text(data['userName'] ?? 'Usuario desconocido'),
                  subtitle: Text(data['userEmail'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                        onPressed: () => _updateRequestStatus(
                          req.id,
                          data['userId'],
                          'rejected',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_rounded, color: Colors.green),
                        onPressed: () => _updateRequestStatus(
                          req.id,
                          data['userId'],
                          'accepted',
                        ),
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
