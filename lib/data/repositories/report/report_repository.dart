import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';

class ReportSubject {
  final String subjectId;
  final String subjectName;
  final double conceptCompletionRate;
  final double practiceCompletionRate;
  final int solvedQuestions;
  final int totalQuestions;

  const ReportSubject({
    required this.subjectId,
    required this.subjectName,
    required this.conceptCompletionRate,
    required this.practiceCompletionRate,
    required this.solvedQuestions,
    required this.totalQuestions,
  });

  factory ReportSubject.fromJson(Map<String, dynamic> json) => ReportSubject(
        subjectId: json['subjectId']?.toString() ?? '',
        subjectName: json['subjectName']?.toString() ?? '',
        conceptCompletionRate: (json['conceptCompletionRate'] as num?)?.toDouble() ?? 0.0,
        practiceCompletionRate: (json['practiceCompletionRate'] as num?)?.toDouble() ?? 0.0,
        solvedQuestions: (json['solvedQuestions'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      );
}

class ReportExamResult {
  final String examName;
  final int correctCount;
  final int totalQuestions;
  final int elapsedSeconds;
  final bool isPassed;
  final String submittedAt;

  const ReportExamResult({
    required this.examName,
    required this.correctCount,
    required this.totalQuestions,
    required this.elapsedSeconds,
    required this.isPassed,
    required this.submittedAt,
  });

  factory ReportExamResult.fromJson(Map<String, dynamic> json) => ReportExamResult(
        examName: json['examName']?.toString() ?? '',
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
        isPassed: json['isPassed'] as bool? ?? false,
        submittedAt: json['submittedAt']?.toString() ?? '',
      );

  double get correctRate => totalQuestions > 0 ? correctCount / totalQuestions : 0.0;
}

class ReportData {
  final String certificateName;
  final double overallProgress;
  final ReportSubject? strongestSubject;
  final ReportSubject? weakestSubject;
  final ReportExamResult? recentExamResult;
  final List<ReportSubject> subjects;

  const ReportData({
    required this.certificateName,
    required this.overallProgress,
    this.strongestSubject,
    this.weakestSubject,
    this.recentExamResult,
    required this.subjects,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    final cert = json['certificate'] as Map<String, dynamic>? ?? {};
    final subjectsList = (json['subjects'] as List?)
            ?.map((e) => ReportSubject.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ReportData(
      certificateName: cert['name']?.toString() ?? '',
      overallProgress: (json['overallProgress'] as num?)?.toDouble() ?? 0.0,
      strongestSubject: json['strongestSubject'] != null
          ? ReportSubject.fromJson(json['strongestSubject'] as Map<String, dynamic>)
          : null,
      weakestSubject: json['weakestSubject'] != null
          ? ReportSubject.fromJson(json['weakestSubject'] as Map<String, dynamic>)
          : null,
      recentExamResult: json['recentExamResult'] != null
          ? ReportExamResult.fromJson(json['recentExamResult'] as Map<String, dynamic>)
          : null,
      subjects: subjectsList,
    );
  }
}

class ReportRepository {
  static final ReportRepository _instance = ReportRepository._internal();
  factory ReportRepository() => _instance;
  ReportRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  Future<ReportData> getReport(String certificateId) async {
    final json = await _api.get('/reports', query: {
      'userId': _session.userId,
      'certificateId': certificateId,
    }) as Map<String, dynamic>;
    return ReportData.fromJson(json);
  }
}
