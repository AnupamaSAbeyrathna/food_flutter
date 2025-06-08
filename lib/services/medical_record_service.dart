import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class MedicalRecordService {
  static const String baseUrl = 'http://192.168.107.72:8000';

  Future<Map<String, dynamic>> analyzeMedicalRecord({
    required File imageFile,
    required String type, // "prescription" | "medication" | "test_result"
    required String title,
    String? note,
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

      request.fields['type'] = type;
      request.fields['title'] = title;
      if (note != null) request.fields['note'] = note;

      request.headers['Authorization'] = 'Bearer $token';

      // Debug logging
      print('Sending file: ${imageFile.path}');
      print('Detected MIME type: $mimeType');
      print('File exists: ${await imageFile.exists()}');

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

  Future<Map<String, dynamic>> updateMedicalRecord({
    required String recordId,
    String? title,
    String? note,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final token = await user.getIdToken();

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/medical/records/$recordId'),
      );

      if (title != null) request.fields['title'] = title;
      if (note != null) request.fields['note'] = note;

      request.headers['Authorization'] = 'Bearer $token';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update medical record: $e');
    }
  }

  Future<Map<String, dynamic>> deleteMedicalRecord(String recordId) async {
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete medical record: $e');
    }
  }
}
