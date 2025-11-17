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

  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _screens.addAll([
      DoctorPatientsScreen(doctorId: widget.doctorId),
      DoctorRemindersScreen(doctorId: widget.doctorId),
      const DoctorSettingsScreen(),
    ]);
  }

  final List<String> _titles = [
    'Pacientes Disponibles',
    'Mis Pacientes',
    'Configuración',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Pacientes'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_information_rounded), label: 'Medicamentos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}
