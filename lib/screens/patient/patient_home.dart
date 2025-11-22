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
  final PageStorageBucket _bucket = PageStorageBucket();

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
    // esquema de color púrpura acorde con settings (match)
    const gradientColors = [
      Color(0xFF7928A1), // ~ #7928A1 (purple)
      Color(0xFF4E1B9A), // ~ #4E1B9A (darker purple)
    ];
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 2,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              _titles[_currentIndex],
              key: ValueKey<String>(_titles[_currentIndex]),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: PageStorage(
            bucket: _bucket,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens.map((w) {
                return Container(
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: w,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4E1B9A),
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.alarm_on_rounded), label: 'Recordatorios'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded), label: 'Progreso'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline_rounded), label: 'Solicitudes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}