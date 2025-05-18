import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_analysis.dart';

class FoodAnalysisService {
  final String apiUrl = 'http://192.168.1.7:8000/analyze';

  Future<FoodAnalysis> analyzeFoodImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
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
