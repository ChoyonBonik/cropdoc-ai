/// Represents a saved leaf scan and its clinical diagnosis report.
class ScanRecord {
  final String id;
  final String imagePath;
  final String diseaseTitle;
  final String severity; // 'healthy', 'moderate', 'severe'
  final String diagnosisText;
  final DateTime timestamp;

  const ScanRecord({
    required this.id,
    required this.imagePath,
    required this.diseaseTitle,
    required this.severity,
    required this.diagnosisText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'diseaseTitle': diseaseTitle,
        'severity': severity,
        'diagnosisText': diagnosisText,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        diseaseTitle: json['diseaseTitle'] as String,
        severity: json['severity'] as String? ?? 'moderate',
        diagnosisText: json['diagnosisText'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
