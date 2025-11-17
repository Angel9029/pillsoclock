import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pillsoclock/core/services/notification_service.dart';
import 'package:pillsoclock/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/patient/patient_home.dart';
import 'screens/admin/admin_home.dart';
import 'providers/reminder_provider.dart';
import 'providers/progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProviderLocal())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Arte dental',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const SplashScreen(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/patientHome': (context) => const PatientHome(),
          '/adminHome': (context) => const AdminHome(),
        },
      ),
    );
  }
}