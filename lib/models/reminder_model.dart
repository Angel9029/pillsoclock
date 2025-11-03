import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String userId;
  final String? doctorId;
  final String name;
  final String description;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final List<DateTime> takenDates;
  final bool immutable;

  ReminderModel({
    required this.id,
    required this.userId,
    this.doctorId,
    required this.name,
    required this.description,
    required this.times,
    required this.startDate,
    this.endDate,
    required this.takenDates,
    required this.immutable,
  });

  // Método copyWith
  ReminderModel copyWith({
    String? id,
    String? userId,
    String? doctorId,
    String? name,
    String? description,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? takenDates,
    bool? immutable,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      name: name ?? this.name,
      description: description ?? this.description,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      takenDates: takenDates ?? this.takenDates,
      immutable: immutable ?? this.immutable,
    );
  }

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: doc.id,
      userId: data['userId'],
      doctorId: data['doctorId'],
      name: data['name'],
      description: data['description'],
      times: List<String>.from(data['times'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      takenDates: [],
      immutable: data['immutable'] ?? true,
    );
  }
}
