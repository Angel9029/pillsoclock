import 'package:flutter/material.dart';
import 'users_screen.dart';
import 'requests_screen.dart';
import 'settings_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    UsersScreen(),
    RequestsScreen(),
    AdminSettingsScreen(),
  ];

  final List<String> _titles = [
    'Gestión de Usuarios',
    'Solicitudes Pendientes',
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
          BottomNavigationBarItem(
              icon: Icon(Icons.supervised_user_circle_rounded),
              label: 'Usuarios'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline_rounded), label: 'Solicitudes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}