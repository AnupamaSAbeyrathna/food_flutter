import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String relationship;
  final String healthNotes;

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relationship,
    required this.healthNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'relationship': relationship,
      'healthNotes': healthNotes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      relationship: map['relationship'],
      healthNotes: map['healthNotes'],
    );
  }
}
