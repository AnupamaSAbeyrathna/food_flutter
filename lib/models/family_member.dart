import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Add this dependency to pubspec.yaml

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

  // Factory constructor to create a default "self" member
  factory FamilyMember.createSelf({
    String? name,
    int? age,
    String? gender,
    String? healthNotes,
  }) {
    const uuid = Uuid();
    return FamilyMember(
      id: uuid.v4(),
      name: name ?? 'Me',
      age: age ?? 25, // Default age, adjust as needed
      gender: gender ?? 'Male',
      relationship: 'Self',
      healthNotes: healthNotes ?? '',
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
  }) async {
    final selfMember = FamilyMember.createSelf(
      name: name,
      age: age,
      gender: gender,
      healthNotes: healthNotes,
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
}