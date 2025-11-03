import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pillsoclock/screens/admin/admin_home.dart';
import 'package:pillsoclock/screens/doctor/doctor_home.dart';
import '../patient/patient_home.dart';
import 'login_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Future<Widget> _resolveHome(User user) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!snap.exists) {
      await FirebaseAuth.instance.signOut();
      return const LoginScreen();
    }

    final role = snap['role'];
    final uid = user.uid;

    if (role == 'admin') {
      return const AdminHome();
    } else if (role == 'doctor') {
      return DoctorHome(doctorId: uid);
    } else {
      return const PatientHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<Widget>(
          future: _resolveHome(user),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return const Scaffold(
                body: Center(child: Text('Error al cargar datos del usuario')),
              );
            }
            return snap.data!;
          },
        );
      },
    );
  }
}
