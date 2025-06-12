// ===== medical_record_model.dart (Server Model) =====
// This model is used for sending data to the server
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String title;
  final String type;
  final String? note;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? analysisResult;
  
  // Family member association fields
  final String familyMemberId;
  final String familyMemberName;
  final String familyMemberRelationship;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.type,
    this.note,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.analysisResult,
    required this.familyMemberId,
    required this.familyMemberName,
    required this.familyMemberRelationship,
  });

  // Convert to JSON for server transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'note': note,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'analysisResult': analysisResult,
      'familyMemberId': familyMemberId,
      'familyMemberName': familyMemberName,
      'familyMemberRelationship': familyMemberRelationship,
    };
  }

  // Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'note': note,
      'imagePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'analysisResult': analysisResult,
      'familyMemberId': familyMemberId,
      'familyMemberName': familyMemberName,
      'familyMemberRelationship': familyMemberRelationship,
    };
  }

  // Create from JSON (server response)
  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      note: json['note'],
      imagePath: json['imagePath'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      analysisResult: json['analysisResult'],
      familyMemberId: json['familyMemberId'] ?? '',
      familyMemberName: json['familyMemberName'] ?? '',
      familyMemberRelationship: json['familyMemberRelationship'] ?? '',
    );
  }

  // Create from Firestore document
  factory MedicalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecord(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      note: data['note'],
      imagePath: data['imagePath'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      analysisResult: data['analysisResult'],
      familyMemberId: data['familyMemberId'] ?? '',
      familyMemberName: data['familyMemberName'] ?? '',
      familyMemberRelationship: data['familyMemberRelationship'] ?? '',
    );
  }

  // Helper method to create a copy with updated fields
  MedicalRecord copyWith({
    String? id,
    String? title,
    String? type,
    String? note,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? analysisResult,
    String? familyMemberId,
    String? familyMemberName,
    String? familyMemberRelationship,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      analysisResult: analysisResult ?? this.analysisResult,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      familyMemberName: familyMemberName ?? this.familyMemberName,
      familyMemberRelationship: familyMemberRelationship ?? this.familyMemberRelationship,
    );
  }
}

class RecordType {
  final String value;
  final String label;
  final dynamic icon;
  final dynamic color;

  RecordType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': value,
      'label': label,
      'icon': icon,
      'color': color,
    };
  }
}