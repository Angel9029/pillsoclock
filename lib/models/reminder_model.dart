import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String userId;
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
    required this.name,
    required this.description,
    required this.times,
    required this.startDate,
    required this.endDate,
    required this.takenDates,
    this.immutable = false,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? _toDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ReminderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      times:
          (data['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startDate: _toDate(data['startDate']) ?? DateTime.now(),
      endDate: _toDate(data['endDate']),
      takenDates:
          (data['takenDates'] as List<dynamic>?)
              ?.map((e) => _toDate(e) ?? DateTime.now())
              .toList() ??
          [],
      immutable: data['immutable'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'description': description,
    'times': times,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'takenDates': takenDates.map((d) => Timestamp.fromDate(d)).toList(),
    'immutable': immutable,
  };
}
