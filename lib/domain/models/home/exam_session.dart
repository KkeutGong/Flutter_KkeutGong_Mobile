class ExamSession {
  final String id;
  final DateTime examDate;
  final int? roundNumber;
  final String examType;
  final String? source;

  ExamSession({
    required this.id,
    required this.examDate,
    required this.roundNumber,
    required this.examType,
    required this.source,
  });

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    return ExamSession(
      id: json['id'] as String,
      examDate: DateTime.parse(json['examDate'] as String),
      roundNumber: json['roundNumber'] as int?,
      examType: (json['examType'] as String?) ?? '필기',
      source: json['source'] as String?,
    );
  }

  bool get isEstimated => source == 'estimated';
}
