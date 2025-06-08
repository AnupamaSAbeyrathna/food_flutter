// lib/models/medical_record_display_model.dart
class MedicalRecordDisplay {
  final String id;
  final String type;
  final String title;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls;
  final MedicalRecordMetadata metadata;

  MedicalRecordDisplay({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.metadata,
  });

  factory MedicalRecordDisplay.fromJson(Map<String, dynamic> json) {
    return MedicalRecordDisplay(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      metadata: MedicalRecordMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrls': imageUrls,
      'metadata': metadata.toJson(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case 'labresult':
        return 'Lab Result';
      case 'prescription':
        return 'Prescription';
      case 'medication':
        return 'Medication';
      default:
        return type.replaceAll('', ' ').toUpperCase();
    }
  }

  bool get hasCriticalResults {
    return metadata.criticalResults?.isNotEmpty ?? false;
  }
}

class MedicalRecordMetadata {
  final String? analysisStatus;
  final String? doctorName;
  final String? facility;
  final String? patientName;
  final String? notes;
  final String? testType;
  final String? testDate;
  final List<TestResult>? testResults;
  final List<TestResult>? criticalResults;
  final List<Medication>? medications;
  final String? diagnosis;
  final String? medicationName;
  final String? expiryDate;
  final Map<String, dynamic>? aiAnalysis;

  MedicalRecordMetadata({
    this.analysisStatus,
    this.doctorName,
    this.facility,
    this.patientName,
    this.notes,
    this.testType,
    this.testDate,
    this.testResults,
    this.criticalResults,
    this.medications,
    this.diagnosis,
    this.medicationName,
    this.expiryDate,
    this.aiAnalysis,
  });

  factory MedicalRecordMetadata.fromJson(Map<String, dynamic> json) {
    return MedicalRecordMetadata(
      analysisStatus: json['analysisStatus'],
      doctorName: json['doctorName'],
      facility: json['facility'],
      patientName: json['patientName'],
      notes: json['notes'],
      testType: json['testType'],
      testDate: json['testDate'],
      testResults: (json['testResults'] as List?)
          ?.map((e) => TestResult.fromJson(e))
          .toList(),
      criticalResults: (json['criticalResults'] as List?)
          ?.map((e) => TestResult.fromJson(e))
          .toList(),
      medications: (json['medications'] as List?)
          ?.map((e) => Medication.fromJson(e))
          .toList(),
      diagnosis: json['diagnosis'],
      medicationName: json['medicationName'],
      expiryDate: json['expiryDate'],
      aiAnalysis: json['aiAnalysis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysisStatus': analysisStatus,
      'doctorName': doctorName,
      'facility': facility,
      'patientName': patientName,
      'notes': notes,
      'testType': testType,
      'testDate': testDate,
      'testResults': testResults?.map((e) => e.toJson()).toList(),
      'criticalResults': criticalResults?.map((e) => e.toJson()).toList(),
      'medications': medications?.map((e) => e.toJson()).toList(),
      'diagnosis': diagnosis,
      'medicationName': medicationName,
      'expiryDate': expiryDate,
      'aiAnalysis': aiAnalysis,
    };
  }
}

class TestResult {
  final String parameter;
  final String value;
  final String unit;
  final String referenceRange;
  final String status;

  TestResult({
    required this.parameter,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      parameter: json['parameter'] ?? '',
      value: json['value'] ?? '',
      unit: json['unit'] ?? '',
      referenceRange: json['referenceRange'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'value': value,
      'unit': unit,
      'referenceRange': referenceRange,
      'status': status,
    };
  }

  bool get isAbnormal {
    return status.toLowerCase() != 'normal';
  }
}

class Medication {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  Medication({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}