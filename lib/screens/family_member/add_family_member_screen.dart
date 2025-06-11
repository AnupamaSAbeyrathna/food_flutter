import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/family_member.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  final String userId;
  final FamilyMember? existingMember;

  const AddFamilyMemberScreen({
    Key? key,
    required this.userId,
    this.existingMember,
  }) : super(key: key);

  @override
  _AddFamilyMemberScreenState createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late int age;
  late String gender;
  late String relationship;
  late String healthNotes;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;
    name = m?.name ?? '';
    age = m?.age ?? 0;
    gender = m?.gender ?? 'Male';
    relationship = m?.relationship ?? '';
    healthNotes = m?.healthNotes ?? '';
  }

  void _saveMember() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final isEditing = widget.existingMember != null;

      final docRef = isEditing
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('familyMembers')
              .doc(widget.existingMember!.id)
          : FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('familyMembers')
              .doc();

      final member = FamilyMember(
        id: docRef.id,
        name: name,
        age: age,
        gender: gender,
        relationship: relationship,
        healthNotes: healthNotes,
      );

      await docRef.set(member.toMap());

      Navigator.pop(context, member); // Return member for feedback
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMember != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Family Member' : 'Add Family Member')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (val) => name = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                initialValue: age > 0 ? age.toString() : '',
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onSaved: (val) => age = int.parse(val!),
                validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid age' : null,
              ),
              DropdownButtonFormField(
                value: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val.toString()),
              ),
              TextFormField(
                initialValue: relationship,
                decoration: const InputDecoration(labelText: 'Relationship'),
                onSaved: (val) => relationship = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter relationship' : null,
              ),
              TextFormField(
                initialValue: healthNotes,
                decoration: const InputDecoration(labelText: 'Health Notes'),
                maxLines: 2,
                onSaved: (val) => healthNotes = val!.trim(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMember,
                child: Text(isEditing ? 'Update Member' : 'Save Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
