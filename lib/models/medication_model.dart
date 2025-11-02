class Medication {
  final String id;
  final String ownerId;
  final bool createdByDoctor;
  final String? doctorId;
  final String name;
  final String description;
  final Map<String, dynamic> schedule;
  final Map<String, dynamic> progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.ownerId,
    required this.createdByDoctor,
    this.doctorId,
    required this.name,
    required this.description,
    required this.schedule,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromMap(Map<String, dynamic> data) {
    return Medication(
      id: data['id'],
      ownerId: data['ownerId'],
      createdByDoctor: data['createdByDoctor'] ?? false,
      doctorId: data['doctorId'],
      name: data['name'],
      description: data['description'],
      schedule: Map<String, dynamic>.from(data['schedule'] ?? {}),
      progress: Map<String, dynamic>.from(data['progress'] ?? {}),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "ownerId": ownerId,
    "createdByDoctor": createdByDoctor,
    "doctorId": doctorId,
    "name": name,
    "description": description,
    "schedule": schedule,
    "progress": progress,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}
