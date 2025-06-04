import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class MedicalRecordService {
  static const String baseUrl = 'http://192.168.107.72:8000';
  
  Future<Map<String, dynamic>> analyzeMedicalRecord({
    required File imageFile,
    required String type,
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
        Uri.parse('$baseUrl/medical/medical_analyze'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      request.fields['type'] = type;
      request.fields['title'] = title;
      request.fields['note'] = note ?? '';

      request.headers['Authorization'] = 'Bearer $token';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze medical record: $e');
    }
  }
}
