import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorPatientsScreen extends StatefulWidget {
  final String doctorId;

  const DoctorPatientsScreen({super.key, required this.doctorId});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _patients = [];
  bool _loading = true;

  // Estado por paciente: 'linked', 'pending', 'none'
  final Map<String, String> _patientStatus = {};

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .get();

    _patients = snapshot.docs;

    // Revisamos solicitudes pendientes y vínculos existentes
    for (var patient in _patients) {
      final patientId = patient.id;

      // ¿Ya está vinculado?
      final linkedSnap = await FirebaseFirestore.instance
          .collection('request_patient')
          .where('patientId', isEqualTo: patientId)
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (linkedSnap.docs.isNotEmpty) {
        _patientStatus[patientId] = 'linked';
      } else {
        // ¿Solicitud pendiente?
        final pendingSnap = await FirebaseFirestore.instance
            .collection('request_patient')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: widget.doctorId)
            .where('status', isEqualTo: 'pending')
            .get();

        _patientStatus[patientId] = pendingSnap.docs.isNotEmpty
            ? 'pending'
            : 'none';
      }
    }

    setState(() => _loading = false);
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final text = _searchController.text.toLowerCase();
    if (text.isEmpty) return true;
    final name = (data['name'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();
    return name.contains(text) || email.contains(text);
  }

  Future<void> _requestLink(
    String patientId,
    String patientName,
    String patientEmail,
  ) async {
    final ref = FirebaseFirestore.instance.collection('request_patient');

    await ref.add({
      'patientId': patientId,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'doctorId': widget.doctorId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _patientStatus[patientId] = 'pending';
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitud enviada ✅')));
    }
  }

  Future<void> _unlinkPatient(String patientId) async {
    final ref = FirebaseFirestore.instance.collection('request_patient');

    // Eliminamos vínculo
    final linkedSnap = await ref
        .where('patientId', isEqualTo: patientId)
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('status', isEqualTo: 'accepted')
        .get();

    for (var doc in linkedSnap.docs) {
      await ref.doc(doc.id).delete();
    }

    // Eliminamos recordatorios creados por este doctor para este paciente
    final remindersSnap = await FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: patientId)
        .where('createdByDoctor', isEqualTo: widget.doctorId)
        .get();

    for (var doc in remindersSnap.docs) {
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(doc.id)
          .delete();
    }

    _patientStatus[patientId] = 'none';
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paciente desvinculado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _patients
        .where((doc) => _matchesFilter(doc.data() as Map<String, dynamic>))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar paciente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final patient = filtered[i];
                      final data = patient.data() as Map<String, dynamic>;
                      final status = _patientStatus[patient.id] ?? 'none';

                      String buttonText = '';
                      void Function()? onPressed;

                      if (status == 'linked') {
                        buttonText = 'Desvincular';
                        onPressed = () => _unlinkPatient(patient.id);
                      } else if (status == 'pending') {
                        buttonText = 'Pendiente';
                        onPressed = null;
                      } else {
                        buttonText = 'Vincular';
                        onPressed = () => _requestLink(
                          patient.id,
                          data['name'] ?? '',
                          data['email'] ?? '',
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(data['name'] ?? ''),
                          subtitle: Text(data['email'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonText == 'Desvincular' ? Colors.red : Colors.white,
                              foregroundColor: buttonText == 'Desvincular' ? Colors.white : Colors.blue,
                              // textStyle: buttonText == 'Desvincular' ? Colors.red : Colors.white
                            ),
                            child: Text(buttonText),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
