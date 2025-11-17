import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/progress_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? 'demo_user';
    final progressProv = Provider.of<ProgressProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de Medicación')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el progreso'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = snapshot.data?.docs ?? [];
          if (reminders.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes recordatorios con progreso registrados.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final doc = reminders[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Sin nombre';
              final description = data['description'] ?? '';
              final times =
                  (data['times'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              final takenDates = (data['takenDates'] as List<dynamic>?) ?? [];

              DateTime? toDate(dynamic v) {
                if (v == null) return null;
                if (v is Timestamp) return v.toDate();
                if (v is String) return DateTime.tryParse(v);
                return null;
              }

              final startDate = toDate(data['startDate']);
              final endDate = toDate(data['endDate']);

              // 🔹 Calculamos el progreso directamente
              final totalDays = endDate != null
                  ? endDate.difference(startDate!).inDays + 1
                  : 30;
              final totalExpected = totalDays * times.length;
              final progress = totalExpected == 0
                  ? 0.0
                  : (takenDates.length / totalExpected).clamp(0.0, 1.0);

              return ProgressCard(
                reminderId: doc.id,
                name: name,
                description: description,
                times: times,
                startDate: startDate,
                endDate: endDate,
                progress: progress,
                takenDatesLenght: takenDates.length,
              );
            },
          );
        },
      ),
    );
  }
}
