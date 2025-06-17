import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Add this dependency to pubspec.yaml

class FamilyMember {
  String id;
  final String name;
  final int age;
  final String gender;
  final String relationship;
  final String healthNotes;
  final String allergies;
  final String longTermMedications; // Fixed naming convention

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relationship,
    required this.healthNotes,
    required this.allergies,
    required this.longTermMedications, // Fixed naming convention
  });

  // Factory constructor to create a default "self" member
  factory FamilyMember.createSelf({
    String? name,
    int? age,
    String? gender,
    String? healthNotes,
    String? allergies,
    String? longTermMedications,  
  }) {
    const uuid = Uuid();
    return FamilyMember(
      id: uuid.v4(),
      name: name ?? 'Me',
      age: age ?? 25, // Default age, adjust as needed
      gender: gender ?? 'Male',
      relationship: 'Self',
      healthNotes: healthNotes ?? '',
      allergies: allergies ?? '',
      longTermMedications: longTermMedications ?? '', // Fixed naming
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'relationship': relationship,
      'healthNotes': healthNotes,
      'allergies': allergies, // Added missing field
      'longTermMedications': longTermMedications, // Added missing field
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
      healthNotes: map['healthNotes'] ?? '', // Added null safety
      allergies: map['allergies'] ?? '', // Added missing field with null safety
      longTermMedications: map['longTermMedications'] ?? '', // Added missing field with null safety
    );
  }
}

// Usage examples:
class FamilyMemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user's family members collection reference
  CollectionReference _getFamilyMembersCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('family_members');
  }

  // Create default self member
  Future<void> createDefaultSelfMember(String userId) async {
    final selfMember = FamilyMember.createSelf();
    
    await _getFamilyMembersCollection(userId)
        .doc(selfMember.id)
        .set(selfMember.toMap());
  }

  // Create self member with custom details
  Future<void> createCustomSelfMember({
    required String userId,
    required String name,
    required int age,
    required String gender,
    String? healthNotes,
    String? allergies, // Added allergies parameter
    String? longTermMedications, // Added medications parameter
  }) async {
    final selfMember = FamilyMember.createSelf(
      name: name,
      age: age,
      gender: gender,
      healthNotes: healthNotes,
      allergies: allergies, // Added allergies
      longTermMedications: longTermMedications, // Added medications
    );
    
    await _getFamilyMembersCollection(userId)
        .doc(selfMember.id)
        .set(selfMember.toMap());
  }

  // Check if self member already exists
  Future<bool> selfMemberExists(String userId) async {
    final querySnapshot = await _getFamilyMembersCollection(userId)
        .where('relationship', isEqualTo: 'Self')
        .limit(1)
        .get();
    
    return querySnapshot.docs.isNotEmpty;
  }

  // Initialize self member if it doesn't exist
  Future<void> initializeSelfMemberIfNeeded(String userId) async {
    final exists = await selfMemberExists(userId);
    if (!exists) {
      await createDefaultSelfMember(userId);
    }
  }

  // Get the self member
  Future<FamilyMember?> getSelfMember(String userId) async {
    final querySnapshot = await _getFamilyMembersCollection(userId)
        .where('relationship', isEqualTo: 'Self')
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return FamilyMember.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Get all family members for a user
  Future<List<FamilyMember>> getAllFamilyMembers(String userId) async {
    final querySnapshot = await _getFamilyMembersCollection(userId).get();
    
    return querySnapshot.docs
        .map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Add a new method to add other family members (not self)
  Future<void> addFamilyMember({
    required String userId,
    required String name,
    required int age,
    required String gender,
    required String relationship,
    String? healthNotes,
    String? allergies,
    String? longTermMedications,
  }) async {
    const uuid = Uuid();
    final familyMember = FamilyMember(
      id: uuid.v4(),
      name: name,
      age: age,
      gender: gender,
      relationship: relationship,
      healthNotes: healthNotes ?? '',
      allergies: allergies ?? '',
      longTermMedications: longTermMedications ?? '',
    );
    
    await _getFamilyMembersCollection(userId)
        .doc(familyMember.id)
        .set(familyMember.toMap());
  }

  // Update family member
  Future<void> updateFamilyMember({
    required String userId,
    required String memberId,
    String? name,
    int? age,
    String? gender,
    String? relationship,
    String? healthNotes,
    String? allergies,
    String? longTermMedications,
  }) async {
    final Map<String, dynamic> updateData = {};
    
    if (name != null) updateData['name'] = name;
    if (age != null) updateData['age'] = age;
    if (gender != null) updateData['gender'] = gender;
    if (relationship != null) updateData['relationship'] = relationship;
    if (healthNotes != null) updateData['healthNotes'] = healthNotes;
    if (allergies != null) updateData['allergies'] = allergies;
    if (longTermMedications != null) updateData['longTermMedications'] = longTermMedications;
    
    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _getFamilyMembersCollection(userId)
          .doc(memberId)
          .update(updateData);
    }
  }
}