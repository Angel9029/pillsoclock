import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/patient/patient_home.dart';
import 'screens/doctor/doctor_home.dart';
import 'screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviderLocal()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pills O\'Clock',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
        ),
        home: const AuthScreen(), // 👈 inicio por ahora
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/patientHome': (context) => const PatientHome(),
          '/doctorHome': (context) => const DoctorHome(),
          '/adminHome': (context) => const AdminHome(),
        },
      ),
    );
  }
}