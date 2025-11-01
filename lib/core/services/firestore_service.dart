// core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setDoc(String path, Map<String, dynamic> data) async {
    await _db.doc(path).set(data);
  }

  Future<DocumentSnapshot> getDoc(String path) async {
    return await _db.doc(path).get();
  }

  // Agrega estas funciones al final de la clase FirestoreService

Future<void> createRoleRequest(String userId) async {
  final requestsRef = _db.collection('requests');
  final existing = await requestsRef
      .where('from_user', isEqualTo: userId)
      .where('type', isEqualTo: 'role_upgrade')
      .where('status', isEqualTo: 'pending')
      .get();

  if (existing.docs.isEmpty) {
    await requestsRef.add({
      'from_user': userId,
      'type': 'role_upgrade',
      'status': 'pending',
      'created_at': Timestamp.now(),
    });
  }
}

Stream<List<Map<String, dynamic>>> getPendingRequests() {
  return _db
      .collection('requests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
}

Future<void> approveRoleRequest(String fromUserId) async {
  await _db.collection('users').doc(fromUserId).update({'role': 'doctor'});
  final query = await _db
      .collection('requests')
      .where('from_user', isEqualTo: fromUserId)
      .where('type', isEqualTo: 'role_upgrade')
      .get();
  for (var doc in query.docs) {
    await doc.reference.update({'status': 'accepted'});
  }
}

Future<void> rejectRoleRequest(String fromUser) async {
  final requestsRef = _db.collection('requests');
  final query = await requestsRef
      .where('from_user', isEqualTo: fromUser)
      .where('type', isEqualTo: 'role_upgrade')
      .get();

  for (var doc in query.docs) {
    await doc.reference.update({'status': 'rejected'});
  }
}

}
