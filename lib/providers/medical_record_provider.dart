import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medical_record_display_model.dart';
import '../models/family_member.dart';
import '../services/medical_record_service.dart';

class MedicalRecordProvider with ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final MedicalRecordService _analysisService = MedicalRecordService();
  final MedicalRecordService _recordsService = MedicalRecordService();

  File? _selectedImage;
  String _selectedType = 'prescription';
  bool _isLoading = false;
  bool _isAnalyzed = false;
  Map<String, dynamic>? _analysisResult;
  List<MedicalRecordDisplay> _records = [];

  // Getters
  File? get selectedImage => _selectedImage;
  String get selectedType => _selectedType;
  bool get isLoading => _isLoading;
  bool get isAnalyzed => _isAnalyzed;
  Map<String, dynamic>? get analysisResult => _analysisResult;
  List<MedicalRecordDisplay> get records => _records;

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
      final result = await _analysisService.analyzeMedicalRecord(
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

  // Fixed method to get records for a specific family member
  Future<void> getRecordsForMember(String memberId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final recordsData = await _recordsService.getMedicalRecordsForFamilyMember(
        familyMemberId: memberId,
      );
      
      // Convert Map<String, dynamic> to MedicalRecordDisplay
      _records = recordsData.map((record) => MedicalRecordDisplay.fromJson(record)).toList();
    } catch (e) {
      _records = [];
      print('Error fetching records for member: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fixed method to get all family records
  Future<void> getAllFamilyRecords() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final recordsData = await _recordsService.getAllMedicalRecords();
      
      // Convert Map<String, dynamic> to MedicalRecordDisplay
      _records = recordsData.map((record) => MedicalRecordDisplay.fromJson(record)).toList();
    } catch (e) {
      _records = [];
      print('Error fetching family records: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fixed method to get user records
  Future<void> getUserRecords(String userId, {String? recordType}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _recordsService.getUserMedicalRecords();
      final recordsData = List<Map<String, dynamic>>.from(response['records'] ?? []);
      
      // Filter by record type if specified
      List<Map<String, dynamic>> filteredRecords = recordsData;
      if (recordType != null && recordType.isNotEmpty) {
        filteredRecords = recordsData.where((record) => record['type'] == recordType).toList();
      }
      
      // Convert Map<String, dynamic> to MedicalRecordDisplay
      _records = filteredRecords.map((record) => MedicalRecordDisplay.fromJson(record)).toList();
    } catch (e) {
      _records = [];
      print('Error fetching user records: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fixed method to update record
  Future<void> updateRecord(String userId, String recordId, {String? title, String? note}) async {
    try {
      await _recordsService.updateMedicalRecord(
        recordId: recordId,
        title: title,
        note: note,
      );
      // Refresh the records after update
      await getUserRecords(userId);
    } catch (e) {
      throw Exception('Failed to update record: $e');
    }
  }

  // Fixed method to delete record
  Future<void> deleteRecord(String userId, String recordId) async {
    try {
      await _recordsService.deleteMedicalRecord(recordId);
      // Refresh the records after deletion
      await getUserRecords(userId);
    } catch (e) {
      throw Exception('Failed to delete record: $e');
    }
  }
}

// Record type model class
class RecordType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  RecordType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}