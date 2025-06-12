import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medical_record_model.dart';
import '../models/family_member.dart';
import '../services/medical_record_service.dart';

class MedicalRecordProvider with ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final MedicalRecordService _service = MedicalRecordService();

  File? _selectedImage;
  String _selectedType = 'prescription';
  bool _isLoading = false;
  bool _isAnalyzed = false;
  Map<String, dynamic>? _analysisResult;

  // Getters
  File? get selectedImage => _selectedImage;
  String get selectedType => _selectedType;
  bool get isLoading => _isLoading;
  bool get isAnalyzed => _isAnalyzed;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  final List<RecordType> recordTypes = [
    RecordType(
      value: 'prescription',
      label: 'Prescription',
      icon: Icons.medication_outlined,
      color: Colors.blue,
    ),
    RecordType(
      value: 'lab_result',
      label: 'Lab Result',
      icon: Icons.science_outlined,
      color: Colors.green,
    ),
    RecordType(
      value: 'medical_report',
      label: 'Medical Report',
      icon: Icons.description_outlined,
      color: Colors.orange,
    ),
    RecordType(
      value: 'other',
      label: 'Other',
      icon: Icons.folder_outlined,
      color: Colors.purple,
    ),
  ];

  void setSelectedType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _isAnalyzed = false;
        _analysisResult = null;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }

  Future<void> analyzeImage({
    required String title,
    String? note,
    required FamilyMember familyMember,
  }) async {
    if (_selectedImage == null) {
      throw Exception('Please select an image first');
    }

    if (title.trim().isEmpty) {
      throw Exception('Please enter a title');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.analyzeMedicalRecord(
        imageFile: _selectedImage!,
        type: _selectedType,
        title: title.trim(),
        note: note?.trim(),
        familyMember: familyMember,
      );

      _analysisResult = result;
      _isAnalyzed = true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetForm() {
    _selectedImage = null;
    _isAnalyzed = false;
    _analysisResult = null;
    _selectedType = 'prescription';
    notifyListeners();
  }

  String getTypeLabel(String value) {
    final type = recordTypes.firstWhere(
      (type) => type.value == value,
      orElse: () => RecordType(
        value: value,
        label: value,
        icon: Icons.folder_outlined,
        color: Colors.grey,
      ),
    );
    return type.label;
  }
}