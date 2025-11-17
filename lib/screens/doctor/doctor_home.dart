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
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Pacientes' : _currentIndex == 1 ? 'Recordatorios' : 'Ajustes'),
        centerTitle: true,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Abre búsqueda dentro de DoctorPatientsScreen (implementar allí)
                // TODO: enviar evento o usar un controlador para enfocar search
              },
            ),
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Abrir pantalla de recordatorios en modo diálogo para crear nuevo
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorRemindersScreen(doctorId: widget.doctorId),
                    fullscreenDialog: true,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
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
