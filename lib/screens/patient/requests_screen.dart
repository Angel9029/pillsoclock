import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('request_patient')
            .where('patientId', isEqualTo: uid)
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

          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final data = req.data() as Map<String, dynamic>;
              final id = req.id;
              final doctorId = data['doctorId'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(doctorId)
                    .get(),
                builder: (context, doctorSnap) {
                  if (!doctorSnap.hasData) {
                    return const ListTile(title: Text('Cargando...'));
                  }

                  final doctorData =
                      doctorSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name = doctorData['name'] ?? 'Médico';
                  final email = doctorData['email'] ?? '';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(
                       vertical: 6,
                     ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_hospital, color: Colors.blue, size: 24),
                      ),
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_rounded, color: Colors.green),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('request_patient')
                                  .doc(id)
                                  .update({'status': 'accepted'});

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Solicitud aceptada'),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('request_patient')
                                  .doc(id)
                                  .update({'status': 'rejected'});

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ Solicitud rechazada'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
