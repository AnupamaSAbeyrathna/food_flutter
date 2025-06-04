class MedicalRecord {
  final String id;
  final String title;
  final String type;
  final String? note;
  final String imagePath;
  final DateTime createdAt;
  final Map<String, dynamic>? analysisResult;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.type,
    this.note,
    required this.imagePath,
    required this.createdAt,
    this.analysisResult,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'note': note,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'analysisResult': analysisResult,
    };
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      note: json['note'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      analysisResult: json['analysisResult'],
    );
  }
}

class RecordType {
  final String value;
  final String label;
  final dynamic icon;
  final dynamic color;

  RecordType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}
