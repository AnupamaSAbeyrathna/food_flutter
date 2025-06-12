// lib/services/family_member_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';

class FamilyMemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'family_members';

  // Get current user's family members collection reference
  CollectionReference _getFamilyMembersCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collectionName);
  }

  // Get all family members for a user (used in your screen)
  Future<List<FamilyMember>> getFamilyMembers(String userId) async {
    try {
      // Simple query without composite index requirement
      final querySnapshot = await _getFamilyMembersCollection(userId).get();
      
      List<FamilyMember> members = querySnapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // If no members exist, create a default self member
      if (members.isEmpty) {
        await createDefaultSelfMember(userId);
        return await getFamilyMembers(userId); // Recursive call to get the created member
      }

      // Sort in memory - "Self" member first, then by name
      members.sort((a, b) {
        if (a.relationship == 'Self') return -1;
        if (b.relationship == 'Self') return 1;
        return a.name.compareTo(b.name);
      });

      return members;
    } catch (e) {
      throw Exception('Failed to load family members: $e');
    }
  }

  // Get a specific family member by ID
  Future<FamilyMember?> getFamilyMember(String userId, String memberId) async {
    try {
      final doc = await _getFamilyMembersCollection(userId)
          .doc(memberId)
          .get();
      
      if (doc.exists) {
        return FamilyMember.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load family member: $e');
    }
  }

  // Create a new family member
  Future<String> createFamilyMember(String userId, FamilyMember member) async {
    try {
      final docRef = _getFamilyMembersCollection(userId).doc(member.id);
      await docRef.set(member.toMap());
      return member.id;
    } catch (e) {
      throw Exception('Failed to create family member: $e');
    }
  }

  // Update an existing family member
  Future<void> updateFamilyMember(String userId, FamilyMember member) async {
    try {
      await _getFamilyMembersCollection(userId)
          .doc(member.id)
          .update(member.toMap());
    } catch (e) {
      throw Exception('Failed to update family member: $e');
    }
  }

  // Delete a family member
  Future<void> deleteFamilyMember(String userId, String memberId) async {
    try {
      // Prevent deletion of self member
      final member = await getFamilyMember(userId, memberId);
      if (member?.relationship == 'Self') {
        throw Exception('Cannot delete self member');
      }
      
      await _getFamilyMembersCollection(userId)
          .doc(memberId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete family member: $e');
    }
  }

  // Create default self member
  Future<void> createDefaultSelfMember(String userId) async {
    try {
      final selfMember = FamilyMember.createSelf();
      await createFamilyMember(userId, selfMember);
    } catch (e) {
      throw Exception('Failed to create default self member: $e');
    }
  }

  // Create self member with custom details
  Future<void> createCustomSelfMember({
    required String userId,
    required String name,
    required int age,
    required String gender,
    String? healthNotes,
  }) async {
    try {
      final selfMember = FamilyMember.createSelf(
        name: name,
        age: age,
        gender: gender,
        healthNotes: healthNotes,
      );
      await createFamilyMember(userId, selfMember);
    } catch (e) {
      throw Exception('Failed to create custom self member: $e');
    }
  }

  // Check if self member already exists
  Future<bool> selfMemberExists(String userId) async {
    try {
      final querySnapshot = await _getFamilyMembersCollection(userId)
          .where('relationship', isEqualTo: 'Self')
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if self member exists: $e');
    }
  }

  // Initialize self member if it doesn't exist
  Future<void> initializeSelfMemberIfNeeded(String userId) async {
    try {
      final exists = await selfMemberExists(userId);
      if (!exists) {
        await createDefaultSelfMember(userId);
      }
    } catch (e) {
      throw Exception('Failed to initialize self member: $e');
    }
  }

  // Get the self member
  Future<FamilyMember?> getSelfMember(String userId) async {
    try {
      final querySnapshot = await _getFamilyMembersCollection(userId)
          .where('relationship', isEqualTo: 'Self')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return FamilyMember.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get self member: $e');
    }
  }

  // Get all family members for a user (alternative method name)
  Future<List<FamilyMember>> getAllFamilyMembers(String userId) async {
    return await getFamilyMembers(userId);
  }

  // Stream family members for real-time updates
  Stream<List<FamilyMember>> streamFamilyMembers(String userId) {
    return _getFamilyMembersCollection(userId)
        .snapshots()
        .map((snapshot) {
          List<FamilyMember> members = snapshot.docs
              .map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Sort in memory - "Self" member first, then by name
          members.sort((a, b) {
            if (a.relationship == 'Self') return -1;
            if (b.relationship == 'Self') return 1;
            return a.name.compareTo(b.name);
          });

          return members;
        });
  }

  // Get family members count
  Future<int> getFamilyMembersCount(String userId) async {
    try {
      final querySnapshot = await _getFamilyMembersCollection(userId).get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get family members count: $e');
    }
  }

  // Search family members by name
  Future<List<FamilyMember>> searchFamilyMembers(String userId, String searchTerm) async {
    try {
      final querySnapshot = await _getFamilyMembersCollection(userId).get();
      
      return querySnapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>))
          .where((member) => member.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search family members: $e');
    }
  }

  // Get family members by relationship
  Future<List<FamilyMember>> getFamilyMembersByRelationship(String userId, String relationship) async {
    try {
      final querySnapshot = await _getFamilyMembersCollection(userId)
          .where('relationship', isEqualTo: relationship)
          .get();
      
      return querySnapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family members by relationship: $e');
    }
  }

  // Batch create multiple family members
  Future<void> createMultipleFamilyMembers(String userId, List<FamilyMember> members) async {
    try {
      final batch = _firestore.batch();
      
      for (final member in members) {
        final docRef = _getFamilyMembersCollection(userId).doc(member.id);
        batch.set(docRef, member.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create multiple family members: $e');
    }
  }

  // Update family member health notes
  Future<void> updateHealthNotes(String userId, String memberId, String healthNotes) async {
    try {
      await _getFamilyMembersCollection(userId)
          .doc(memberId)
          .update({'healthNotes': healthNotes});
    } catch (e) {
      throw Exception('Failed to update health notes: $e');
    }
  }
}