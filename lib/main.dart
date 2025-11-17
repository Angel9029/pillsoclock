import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pillsoclock/core/services/notification_service.dart';
import 'package:pillsoclock/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/patient/patient_home.dart';
import 'screens/admin/admin_home.dart';
import 'screens/doctor/doctor_home.dart';
import 'providers/reminder_provider.dart';
import 'providers/progress_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/auth_service.dart'; // para obtener current user

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  // Hook: registrar callback para acciones desde notificaciones (ej. marcar "tomada")
  NotificationService.setOnNotificationAction((payload, actionId) async {
    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null || payload == null) return;
      // payload esperado: puede ser "reminderId[_<hora>]" según donde lo crees.
      final reminderId = payload.split('_').first;

      // Registrar log
      await FirebaseFirestore.instance.collection('reminder_logs').add({
        'reminder_id': reminderId,
        'user_id': uid,
        'timestamp': DateTime.now(),
        'status': actionId == 'TAKEN' ? 'taken' : 'unknown',
      });

      // Si la acción fue "TAKEN", actualizar takenDates del reminder
      if (actionId == 'TAKEN') {
        await FirebaseFirestore.instance.collection('reminders').doc(reminderId).update({
          'takenDates': FieldValue.arrayUnion([Timestamp.fromDate(DateTime.now())]),
        });
      }
    } catch (e) {
      // ignora errores de background
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviderLocal()),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pills O\'Clock',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        // Puedes afinar fuentes y colores aquí para look moderno
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/patientHome': (context) => const PatientHome(),
        '/adminHome': (context) => const AdminHome(),
        '/doctorHome': (context) => DoctorHome(doctorId: Provider.of<AuthProviderLocal>(context, listen: false).user?.uid ?? ''),
      },
    );
  }
}