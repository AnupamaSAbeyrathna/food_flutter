import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_family_member_screen.dart';
import '../../models/family_member.dart';

class FamilyMembersScreen extends StatelessWidget {
  final String userId;

  const FamilyMembersScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final membersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('family_members');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final newMember = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFamilyMemberScreen(userId: userId),
                ),
              );
              if (newMember != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${newMember.name}')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: membersRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading members'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!.docs.map((doc) {
            final map = doc.data() as Map<String, dynamic>;
            return FamilyMember.fromMap(map);
          }).toList();

          if (members.isEmpty) {
            return const Center(child: Text('No family members yet.'));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, index) {
              final member = members[index];
              return ListTile(
                title: Text('${member.name} (${member.relationship})'),
                subtitle: Text('Age: ${member.age}, ${member.gender}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updatedMember = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFamilyMemberScreen(
                          userId: userId,
                          existingMember: member,
                        ),
                      ),
                    );

                    if (updatedMember != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${updatedMember.name}')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
