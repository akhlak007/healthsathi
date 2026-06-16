import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../enums/reminder_type.dart';

class MedicineReminderModel {
  final String id;
  final String medicineName;
  final String dosage;
  final String instruction;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> times;
  final bool isActive;
  final DateTime createdAt;
  final ReminderType type;

  MedicineReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.instruction,
    required this.startDate,
    required this.endDate,
    required this.times,
    required this.isActive,
    required this.createdAt,
    this.type = ReminderType.medicine,
  });

  MedicineReminderModel copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    String? instruction,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? times,
    bool? isActive,
    DateTime? createdAt,
    ReminderType? type,
  }) {
    return MedicineReminderModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      instruction: instruction ?? this.instruction,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      times: times ?? this.times,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'instruction': instruction,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'times': times,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
    };
  }

  factory MedicineReminderModel.fromMap(Map<String, dynamic> map) {
    return MedicineReminderModel(
      id: map['id'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      instruction: map['instruction'] ?? '',
      startDate: map['startDate'] != null 
          ? (map['startDate'] is Timestamp ? (map['startDate'] as Timestamp).toDate() : DateTime.parse(map['startDate'])) 
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? (map['endDate'] is Timestamp ? (map['endDate'] as Timestamp).toDate() : DateTime.parse(map['endDate'])) 
          : DateTime.now(),
      times: List<String>.from(map['times'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.parse(map['createdAt'])) 
          : DateTime.now(),
      type: map['type'] != null ? ReminderType.fromString(map['type']) : ReminderType.medicine,
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicineReminderModel.fromJson(String source) => MedicineReminderModel.fromMap(json.decode(source));
}
