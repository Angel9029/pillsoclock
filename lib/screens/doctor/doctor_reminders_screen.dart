import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_patient_reminders_screen.dart';

class DoctorRemindersScreen extends StatefulWidget {
  final String doctorId;
  const DoctorRemindersScreen({super.key, required this.doctorId});

  @override
  State<DoctorRemindersScreen> createState() => _DoctorRemindersScreenState();
}

class _DoctorRemindersScreenState extends State<DoctorRemindersScreen> {
  List<DocumentSnapshot> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLinkedPatients();
  }

  Future<void> _loadLinkedPatients() async {
    setState(() => _loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('request_patient')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final List<String> patientIds = snap.docs
        .map((d) => d['patientId'] as String)
        .toList();

    if (patientIds.isEmpty) {
      setState(() {
        _patients = [];
        _loading = false;
      });
      return;
    }

    final patientSnap = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: patientIds)
        .get();

    _patients = patientSnap.docs;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Paciente')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
          ? const Center(child: Text('No hay pacientes vinculados.'))
          : ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (ctx, i) {
                final patient = _patients[i];
                final data = patient.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(data['name'] ?? ''),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorPatientRemindersScreen(
                              doctorId: widget.doctorId,
                              patientId: patient.id,
                              patientName: data['name'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: const Text('Gestionar'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
