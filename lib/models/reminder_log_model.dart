// lib/models/reminder_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderLog {
  final String id;
  final String reminderId;
  final String userId;
  final Timestamp expectedAt; // when it was supposed to be taken
  final String status; // 'taken' | 'missed'
  final Timestamp recordedAt;

  ReminderLog({
    required this.id,
    required this.reminderId,
    required this.userId,
    required this.expectedAt,
    required this.status,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderId': reminderId,
      'userId': userId,
      'expectedAt': expectedAt,
      'status': status,
      'recordedAt': recordedAt,
    };
  }

  factory ReminderLog.fromMap(Map<String, dynamic> m) {
    return ReminderLog(
      id: m['id'] ?? '',
      reminderId: m['reminderId'] ?? '',
      userId: m['userId'] ?? '',
      expectedAt: m['expectedAt'] ?? Timestamp.now(),
      status: m['status'] ?? 'missed',
      recordedAt: m['recordedAt'] ?? Timestamp.now(),
    );
  }
}