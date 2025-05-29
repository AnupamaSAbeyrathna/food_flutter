import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_analysis.dart';
import '../services/food_analysis_service.dart';

class FoodAnalysisProvider with ChangeNotifier {
  final FoodAnalysisService _service = FoodAnalysisService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  File? _selectedImage;
  String? _selectedImageName;
  FoodAnalysis? _analysisResult;
  String? _error;
  bool _hasUploaded = false; // ✅ Track upload

  bool get isLoading => _isLoading;
  File? get selectedImage => _selectedImage;
  String? get selectedImageName => _selectedImageName;
  FoodAnalysis? get analysisResult => _analysisResult;
  String? get error => _error;
  bool get hasUploaded => _hasUploaded; // ✅ Getter for upload status

  void markUploaded() {
    _hasUploaded = true; // ✅ Mark uploaded
  }

  void setSelectedImage(File image) {
    _selectedImage = image;
    _selectedImageName = image.path.split('/').last;
    _analysisResult = null;
    _error = null;
    _hasUploaded = false; // ✅ Reset on new image
    notifyListeners();
  }

  Future<void> pickAndSetImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: source);
      if (pickedImage == null) return;
      _selectedImage = File(pickedImage.path);
      _selectedImageName = pickedImage.name;
      _analysisResult = null;
      _error = null;
      _hasUploaded = false; // ✅ Reset on new image
      notifyListeners();
    } catch (e) {
      _error = "Failed to pick image: $e";
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    _selectedImageName = null;
    _analysisResult = null;
    _error = null;
    _hasUploaded = false; // ✅ Reset on clear
    notifyListeners();
  }

  Future<void> analyzeImage() async {
    if (_selectedImage == null) {
      _error = 'No image selected';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _analysisResult = await _service.analyzeFoodImage(_selectedImage!);
    } catch (e) {
      _error = e.toString();
      _analysisResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
