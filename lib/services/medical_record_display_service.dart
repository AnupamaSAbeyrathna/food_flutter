// lib/services/medical_records_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medical_record_display_model.dart';
import '../utils/api_config.dart';

class MedicalRecordsService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  // Helper method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  Future<List<MedicalRecordDisplay>> getUserRecords(String userId, {String? recordType}) async {
    try {
      String url = '$baseUrl/medical/users/$userId/medical-records';
      if (recordType != null && recordType.isNotEmpty) {
        url += '?type=$recordType';
      }
      
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> data = responseData['data'];
        return data.map((record) => MedicalRecordDisplay.fromJson(record)).toList();
      } else {
        throw Exception('Failed to load medical records');
      }
    } catch (e) {
      throw Exception('Error fetching records: $e');
    }
  }

  Future<MedicalRecordDisplay?> getRecordById(String userId, String memberId, String recordId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records/$recordId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return MedicalRecordDisplay.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load record');
      }
    } catch (e) {
      throw Exception('Error fetching record: $e');
    }
  }
  
  Future<MedicalRecordDisplay> updateRecord(
    String userId, 
    String memberId,
    String recordId, 
    {String? title, String? note, Map<String, dynamic>? aiAnalysis}
  ) async {
    try {
      Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (note != null) updateData['note'] = note;
      if (aiAnalysis != null) updateData['ai_analysis'] = aiAnalysis;

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records/$recordId'),
        headers: headers,
        body: json.encode(updateData),
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return MedicalRecordDisplay.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to update record');
      }
    } catch (e) {
      throw Exception('Error updating record: $e');
    }
  }

  Future<bool> deleteRecord(String userId, String memberId, String recordId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records/$recordId'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting record: $e');
    }
  }

  Future<List<MedicalRecordDisplay>> getAllFamilyRecords(String memberId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/medical/family-members/$memberId/medical-records'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> jsonList = responseData['data'];
        return jsonList.map((json) => MedicalRecordDisplay.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch family medical records');
      }
    } catch (e) {
      throw Exception('Error fetching family records: $e');
    }
  }

  Future<List<MedicalRecordDisplay>> getRecordsForMember(String userId, String memberId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> jsonList = responseData['data'];
        return jsonList.map((json) => MedicalRecordDisplay.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch records for member');
      }
    } catch (e) {
      throw Exception('Error fetching records for member: $e');
    }
  }

  // NEW FAMILY MEMBER RECORD METHODS
  Future<MedicalRecordDisplay?> getRecordForMember(String userId, String memberId, String recordId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records/$recordId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return MedicalRecordDisplay.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load family member record');
      }
    } catch (e) {
      throw Exception('Error fetching family member record: $e');
    }
  }

  Future<bool> deleteRecordForMember(String userId, String memberId, String recordId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records/$recordId'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting family member record: $e');
    }
  }

  Future<MedicalRecordDisplay> updateRecordForMember(
    String userId, 
    String memberId,
    String recordId, 
    {String? title, String? note, Map<String, dynamic>? aiAnalysis}
  ) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (title != null) updateData['title'] = title;
      if (note != null) updateData['note'] = note;
      if (aiAnalysis != null) updateData['ai_analysis'] = aiAnalysis;
      print('updateData: title:${updateData['title']}, note:${updateData['note']}, aiAnalysis:${updateData['ai_analysis']}');

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/medical/users/$userId/family-members/$memberId/medical-records/$recordId'),
        headers: headers,
        body: json.encode(updateData),
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return MedicalRecordDisplay.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to update family member record');
      }
    } catch (e) {
      throw Exception('Error updating family member record: $e');
    }
  }
}