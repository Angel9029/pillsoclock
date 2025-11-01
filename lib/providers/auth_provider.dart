// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';

class AuthProviderLocal extends ChangeNotifier {
  final AuthService _service = AuthService();
  User? user;
  String? role;
  bool loading = true;

  AuthProviderLocal() {
    _init();
  }

  void _init() {
    // listen auth changes
    _service.authChanges.listen((u) async {
      user = u;
      if (user == null) {
        role = null;
        loading = false;
        notifyListeners();
        return;
      }

      try {
        final r = await _service.getRoleForUid(user!.uid);
        role = r;
      } catch (e) {
        role = null;
      }

      loading = false;
      notifyListeners();
    });

    // fallback: don't stay loading forever
    Future.delayed(const Duration(seconds: 5), () {
      if (loading) {
        loading = false;
        notifyListeners();
      }
    });
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _service.register(email: email, password: password, name: name);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _service.login(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _service.logout();
  }
}