import 'package:flutter/material.dart';
import 'doctor_patients_screen.dart';
import 'doctor_reminders_screen.dart';
import 'doctor_settings_screen.dart';

class DoctorHome extends StatefulWidget {
  final String doctorId;
  const DoctorHome({super.key, required this.doctorId});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DoctorPatientsScreen(doctorId: widget.doctorId),
      DoctorRemindersScreen(doctorId: widget.doctorId),
      const DoctorSettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_information),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
