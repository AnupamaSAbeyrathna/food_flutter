import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../utils/api_config.dart';
import '../models/family_member.dart';

class MedicalRecordService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> analyzeMedicalRecord({
    required File imageFile,
    required String type, // "prescription" | "medication" | "test_result"
    required String title,
    String? note,
    required FamilyMember familyMember,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/medical/analyze'), // Updated endpoint
      );

      // Get MIME type from file path
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      // Add file with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Add form fields
      request.fields['type'] = type;
      request.fields['title'] = title;
      if (note != null) request.fields['note'] = note;
      
      // Add family member data
      request.fields['family_member_id'] = familyMember.id;
      request.fields['family_member_name'] = familyMember.name;
      request.fields['family_member_relationship'] = familyMember.relationship;
      request.fields['family_member_age'] = familyMember.age.toString();
      request.fields['family_member_gender'] = familyMember.gender;
      if (familyMember.healthNotes.isNotEmpty) {
        request.fields['family_member_health_notes'] = familyMember.healthNotes;
      }

      // Add authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Debug logging
      print('--- Upload Debug Info ---');
      print('file_path                  : ${imageFile.path}');
      print('mime_type                  : $mimeType');
      print('file_exists                : ${await imageFile.exists()}');
      print('family_member_id           : ${familyMember.id}');
      print('family_member_name         : ${familyMember.name}');
      print('family_member_relationship : ${familyMember.relationship}');
      print('family_member_age          : ${familyMember.age}');
      print('family_member_gender       : ${familyMember.gender}');
      print('family_member_health_notes : ${familyMember.healthNotes}');
      print('--------------------------');



      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Server error response: ${response.body}');
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in analyzeMedicalRecord: $e');
      throw Exception('Failed to analyze medical record: $e');
    }
  }

  // Method to get medical records for a specific family member
  Future<List<Map<String, dynamic>>> getMedicalRecordsForFamilyMember({
    required String familyMemberId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records?familyMemberId=$familyMemberId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        throw Exception('Failed to fetch medical records: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching medical records: $e');
      throw Exception('Failed to fetch medical records: $e');
    }
  }

  // Method to get all medical records for all family members
  Future<List<Map<String, dynamic>>> getAllMedicalRecords() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        throw Exception('Failed to fetch medical records: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all medical records: $e');
      throw Exception('Failed to fetch all medical records: $e');
    }
  }

  // Method to delete a medical record
  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/medical/records/$recordId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medical record: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting medical record: $e');
      throw Exception('Failed to delete medical record: $e');
    }
  }

  // Method to update a medical record
  Future<Map<String, dynamic>> updateMedicalRecord({
    required String recordId,
    String? title,
    String? note,
    String? type,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (note != null) body['note'] = note;
      if (type != null) body['type'] = type;

      final response = await http.put(
        Uri.parse('$baseUrl/medical/records/$recordId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update medical record: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating medical record: $e');
      throw Exception('Failed to update medical record: $e');
    }
  }

  Future<Map<String, dynamic>> getUserMedicalRecords() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch medical records: $e');
    }
  }

  Future<Map<String, dynamic>> getMedicalRecord(String recordId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records/$recordId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch medical record: $e');
    }
  }

  // Future<Map<String, dynamic>> updateMedicalRecord({
  //   required String recordId,
  //   String? title,
  //   String? note,
  // }) async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       throw Exception('User not logged in');
  //     }
  //     final token = await user.getIdToken();

  //     var request = http.MultipartRequest(
  //       'PUT',
  //       Uri.parse('$baseUrl/medical/records/$recordId'),
  //     );

  //     if (title != null) request.fields['title'] = title;
  //     if (note != null) request.fields['note'] = note;

  //     request.headers['Authorization'] = 'Bearer $token';

  //     var streamedResponse = await request.send();
  //     var response = await http.Response.fromStream(streamedResponse);

  //     if (response.statusCode == 200) {
  //       return json.decode(response.body);
  //     } else {
  //       throw Exception('Server error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to update medical record: $e');
  //   }
  // }

  // Future<Map<String, dynamic>> deleteMedicalRecord(String recordId) async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       throw Exception('User not logged in');
  //     }
  //     final token = await user.getIdToken();

  //     final response = await http.delete(
  //       Uri.parse('$baseUrl/medical/records/$recordId'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       return json.decode(response.body);
  //     } else {
  //       throw Exception('Server error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to delete medical record: $e');
  //   }
  // }
}
