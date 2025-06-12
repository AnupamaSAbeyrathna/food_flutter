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
  
  // Family member display information
  final String familyMemberId;
  final String familyMemberName;
  final String familyMemberRelationship;

  MedicalRecordDisplay({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.metadata,
    required this.familyMemberId,
    required this.familyMemberName,
    required this.familyMemberRelationship,
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
      familyMemberId: json['familyMemberId'] ?? '',
      familyMemberName: json['familyMemberName'] ?? '',
      familyMemberRelationship: json['familyMemberRelationship'] ?? '',
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
      'familyMemberId': familyMemberId,
      'familyMemberName': familyMemberName,
      'familyMemberRelationship': familyMemberRelationship,
    };
  }

  // Display-specific getters
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'labresult':
        return 'Lab Result';
      case 'prescription':
        return 'Prescription';
      case 'medication':
        return 'Medication';
      case 'xray':
        return 'X-Ray';
      case 'mri':
        return 'MRI';
      case 'ct':
        return 'CT Scan';
      case 'ultrasound':
        return 'Ultrasound';
      default:
        return type.replaceAll('_', ' ').split(' ')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
            .join(' ');
    }
  }

  bool get hasCriticalResults {
    return metadata.criticalResults?.isNotEmpty ?? false;
  }

  bool get isSelfRecord => familyMemberRelationship.toLowerCase() == 'self';

  String get patientDisplayName {
    return isSelfRecord ? 'You' : familyMemberName;
  }

  String get patientDetailDisplayName {
    if (isSelfRecord) return 'Your Record';
    return '$familyMemberName\'s Record ($familyMemberRelationship)';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Status indicators for UI
  String get statusColor {
    if (hasCriticalResults) return 'red';
    if (metadata.analysisStatus == 'success') return 'green';
    if (metadata.analysisStatus == 'pending') return 'orange';
    return 'grey';
  }

  bool get needsAttention => hasCriticalResults;
  
  String get statusText {
    if (hasCriticalResults) return 'Critical Results';
    if (metadata.analysisStatus == 'success') return 'Analyzed';
    if (metadata.analysisStatus == 'pending') return 'Processing';
    return 'Not Analyzed';
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
  final String? prescriptionDate;
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
    this.prescriptionDate,
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
      prescriptionDate: json['prescriptionDate'],
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
      'prescriptionDate': prescriptionDate,
      'testResults': testResults?.map((e) => e.toJson()).toList(),
      'criticalResults': criticalResults?.map((e) => e.toJson()).toList(),
      'medications': medications?.map((e) => e.toJson()).toList(),
      'diagnosis': diagnosis,
      'medicationName': medicationName,
      'expiryDate': expiryDate,
      'aiAnalysis': aiAnalysis,
    };
  }

  // Display helpers
  String get facilityDisplayName => facility ?? 'Unknown Facility';
  String get doctorDisplayName => doctorName ?? 'Unknown Doctor';
  int get medicationCount => medications?.length ?? 0;
  int get testResultCount => testResults?.length ?? 0;
  int get criticalResultCount => criticalResults?.length ?? 0;
  
  bool get hasResults => testResults?.isNotEmpty ?? false;
  bool get hasMedications => medications?.isNotEmpty ?? false;
  bool get isAnalyzed => analysisStatus == 'success';
  
  String get medicationSummary {
    if (medications?.isEmpty ?? true) return 'No medications';
    if (medications!.length == 1) return '1 medication';
    return '${medications!.length} medications';
  }
  
  String get testResultSummary {
    if (testResults?.isEmpty ?? true) return 'No test results';
    if (testResults!.length == 1) return '1 test result';
    return '${testResults!.length} test results';
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

  bool get isAbnormal => status.toLowerCase() != 'normal';
  bool get isCritical => status.toLowerCase().contains('critical') || 
                        status.toLowerCase().contains('high') || 
                        status.toLowerCase().contains('low');
  
  String get displayValue => value.isEmpty ? 'N/A' : '$value${unit.isNotEmpty ? ' $unit' : ''}';
  
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'green';
      case 'high':
      case 'low':
        return 'orange';
      case 'critical':
        return 'red';
      default:
        return 'grey';
    }
  }
  
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      case 'critical':
        return 'Critical';
      default:
        return status;
    }
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

  // Display helpers
  String get displayName => name.isEmpty ? 'Unknown Medication' : name;
  
  String get dosageDisplay {
    if (dosage == null || dosage!.isEmpty) return '';
    return dosage!;
  }
  
  String get frequencyDisplay {
    if (frequency == null || frequency!.isEmpty) return '';
    switch (frequency!.toUpperCase()) {
      case 'QD':
        return 'Once daily';
      case 'BID':
        return 'Twice daily';
      case 'TID':
        return 'Three times daily';
      case 'QID':
        return 'Four times daily';
      default:
        return frequency!;
    }
  }
  
  String get fullInstructions {
    final parts = <String>[];
    if (dosageDisplay.isNotEmpty) parts.add(dosageDisplay);
    if (frequencyDisplay.isNotEmpty) parts.add(frequencyDisplay);
    if (instructions != null && instructions!.isNotEmpty) parts.add(instructions!);
    return parts.join(' • ');
  }
  
  String get shortDescription {
    final parts = <String>[];
    if (dosageDisplay.isNotEmpty) parts.add(dosageDisplay);
    if (frequencyDisplay.isNotEmpty) parts.add(frequencyDisplay);
    return parts.isEmpty ? name : '$name - ${parts.join(' ')}';
  }
}