import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final int dose;
  final int hour;
  final int minute;
  final int repeatEveryHours;
  final DateTime? endDate;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.dose,
    required this.hour,
    required this.minute,
    this.repeatEveryHours = 24,
    this.endDate,
    required this.createdAt,
  });

  Reminder copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    int? dose,
    int? hour,
    int? minute,
    int? repeatEveryHours,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      dose: dose ?? this.dose,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatEveryHours: repeatEveryHours ?? this.repeatEveryHours,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Reminder.fromMap(Map<String, dynamic> m) {
    return Reminder(
      id: m['id'] ?? '',
      ownerId: m['ownerId'] ?? '',
      name: m['name'] ?? '',
      description: m['description'] ?? '',
      dose: m['dose'] ?? 0,
      hour: m['hour'] ?? 0,
      minute: m['minute'] ?? 0,
      repeatEveryHours: m['repeatEveryHours'] ?? 24,
      endDate: m['endDate'] != null
          ? (m['endDate'] as Timestamp).toDate()
          : null,
      createdAt: (m['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'dose': dose,
      'hour': hour,
      'minute': minute,
      'repeatEveryHours': repeatEveryHours,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
