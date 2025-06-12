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

  // Helper method to get auth headers with proper content type
  Future<Map<String, String>> _getAuthHeaders({bool isJson = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    
    final token = await user.getIdToken();
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };
    
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> analyzeMedicalRecord({
    required File imageFile,
    required String type, // "prescription" | "lab_result" | "medical_report" | "other"
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
        Uri.parse('$baseUrl/medical/analyze'),
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
      if (note != null && note.isNotEmpty) {
        request.fields['note'] = note;
      }
      
      // Add family member data
      request.fields['family_member_id'] = familyMember.id;
      request.fields['family_member_name'] = familyMember.name;
      request.fields['family_member_relationship'] = familyMember.relationship;
      request.fields['family_member_age'] = familyMember.age.toString();
      request.fields['family_member_gender'] = familyMember.gender;
      if (familyMember.healthNotes.isNotEmpty) {
        request.fields['family_member_health_notes'] = familyMember.healthNotes;
      }

      request.headers['Authorization'] = 'Bearer $token';

      // Debug logging
      print('Sending file: ${imageFile.path}');
      print('Detected MIME type: $mimeType');
      print('File exists: ${await imageFile.exists()}');
      print('Family member: ${familyMember.name} (${familyMember.relationship})');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Server error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('Error in analyzeMedicalRecord: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e is FormatException) {
        throw Exception('Invalid response format from server');
      } else {
        throw Exception('Failed to analyze medical record: $e');
      }
    }
  }

  // Method to get medical records for a specific family member
  Future<List<Map<String, dynamic>>> getMedicalRecordsForFamilyMember({
    required String familyMemberId,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final uri = Uri.parse('$baseUrl/medical/records').replace(
        queryParameters: {'familyMemberId': familyMemberId},
      );

      final response = await http.get(uri, headers: headers);

      print('Get records response status: ${response.statusCode}');
      print('Get records response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        final errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Failed to fetch medical records: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error fetching medical records: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to fetch medical records: $e');
      }
    }
  }

  // Method to get all medical records for all family members
  Future<List<Map<String, dynamic>>> getAllMedicalRecords() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records'),
        headers: headers,
      );

      print('Get all records response status: ${response.statusCode}');
      print('Get all records response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        final errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Failed to fetch medical records: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error fetching all medical records: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to fetch all medical records: $e');
      }
    }
  }

  // Method to delete a medical record
  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      final headers = await _getAuthHeaders(isJson: false);

      final response = await http.delete(
        Uri.parse('$baseUrl/medical/records/$recordId'),
        headers: headers,
      );

      print('Delete record response status: ${response.statusCode}');
      print('Delete record response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Failed to delete medical record: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error deleting medical record: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to delete medical record: $e');
      }
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
      final headers = await _getAuthHeaders();

      final body = <String, dynamic>{};
      if (title != null && title.isNotEmpty) body['title'] = title;
      if (note != null) body['note'] = note; // Allow empty notes
      if (type != null && type.isNotEmpty) body['type'] = type;

      if (body.isEmpty) {
        throw Exception('No fields to update');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/medical/records/$recordId'),
        headers: headers,
        body: json.encode(body),
      );

      print('Update record response status: ${response.statusCode}');
      print('Update record response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Failed to update medical record: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error updating medical record: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to update medical record: $e');
      }
    }
  }

  // Method to get user's medical records
  Future<Map<String, dynamic>> getUserMedicalRecords() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records'),
        headers: headers,
      );

      print('Get user records response status: ${response.statusCode}');
      print('Get user records response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Server error: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error fetching user medical records: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to fetch medical records: $e');
      }
    }
  }

  // Method to get a specific medical record
  Future<Map<String, dynamic>> getMedicalRecord(String recordId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/medical/records/$recordId'),
        headers: headers,
      );

      print('Get single record response status: ${response.statusCode}');
      print('Get single record response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Server error: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error fetching medical record: $e');
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to fetch medical record: $e');
      }
    }
  }
}