import 'package:flutter/material.dart';
import 'reminders_screen.dart';
import 'progress_screen.dart';
import 'requests_screen.dart';
import 'settings_screen.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RemindersScreen(),
    ProgressScreen(),
    RequestsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Recordatorios', backgroundColor: Colors.blue),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progreso', backgroundColor: Colors.blue),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Solicitudes', backgroundColor: Colors.blue),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes', backgroundColor: Colors.blue),
        ],
      ),
    );
  }
}