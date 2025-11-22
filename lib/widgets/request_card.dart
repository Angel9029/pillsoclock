import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const RequestCard({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  Future<void> _acceptRequest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'accepted'});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Solicitud aceptada')));
  }

  Future<void> _rejectRequest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'rejected'});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada')));
  }

  @override
  Widget build(BuildContext context) {
    final name = requestData['doctor_name'] ?? 'Médico';
    final email = requestData['doctor_email'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(name),
        subtitle: Text(email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(context),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectRequest(context),
            ),
          ],
        ),
      ),
    );
  }
}