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

  final List<String> _titles = [
    'Mis Recordatorios',
    'Progreso',
    'Solicitudes Médicas',
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
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm_on_rounded), label: 'Recordatorios'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline_rounded), label: 'Solicitudes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}