import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_analysis.dart';

class FoodAnalysisService {
  // TODO: Change to the correct API URL
  static const String baseUrl = 'http://192.168.107.72:8000';
  final String apiUrl = '$baseUrl/food/food_analyze';

  Future<FoodAnalysis> analyzeFoodImage(File imageFile) async {
    try {
      // ✅ Get the Firebase ID token
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] =
          'Bearer $idToken'; // ✅ Add token to header
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error sending image for analysis: $e');
    }
  }

  FoodAnalysis _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return FoodAnalysis.fromJson(data);
    } else {
      throw Exception(
        'Failed to analyze image: ${response.statusCode} ${response.body}',
      );
    }
  }
}
