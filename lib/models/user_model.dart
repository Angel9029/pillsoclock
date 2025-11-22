// models/user_model.dart
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) {
    return AppUser(
      uid: m['uid'] ?? '',
      email: m['email'] ?? '',
      name: m['name'] ?? '',
      role: m['role'] ?? 'patient',
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'name': name, 'role': role};
  }
}