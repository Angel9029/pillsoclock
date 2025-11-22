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
  final PageStorageBucket _bucket = PageStorageBucket();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DoctorPatientsScreen(doctorId: widget.doctorId),
      DoctorRemindersScreen(doctorId: widget.doctorId),
      const DoctorSettingsScreen(),
    ];
  }

  final List<String> _titles = [
    'Pacientes Disponibles',
    'Mis Pacientes',
    'Configuración',
  ];


  @override
  Widget build(BuildContext context) {
    // Doctor color scheme (same used in settings_screen)
    const gradientColors = [Color(0xFF1976D2), Color(0xFF0D47A1)];
    final bool showFab = _currentIndex != 2;

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
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
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
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Pacientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_information_rounded),
            label: 'Medicamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
