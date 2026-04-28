import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/domain/models/study/exam_result.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';

class MockExamSession {
  final String examName;
  final int timeLimitMinutes;
  final List<Question> questions;
  const MockExamSession({
    required this.examName,
    required this.timeLimitMinutes,
    required this.questions,
  });
}

class MockExamRepository {
  static final MockExamRepository _instance = MockExamRepository._internal();
  factory MockExamRepository() => _instance;
  MockExamRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  Future<MockExamSession> startExam({String? examName}) async {
    final json = await _api.post('/study/mock-exams/start', body: {
      'certificateId': _session.currentCertificateId,
      if (examName != null) 'examName': examName,
    }) as Map<String, dynamic>;

    return MockExamSession(
      examName: json['examName'] as String,
      timeLimitMinutes: json['timeLimitMinutes'] as int,
      questions: (json['questions'] as List)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ExamResult> submitExam({
    required String examName,
    required Map<String, int> answers,
    required int elapsedSeconds,
  }) async {
    final json = await _api.post('/study/mock-exams/submit', body: {
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
      'examName': examName,
      'answers': answers,
      'elapsedSeconds': elapsedSeconds,
    }) as Map<String, dynamic>;

    final scoresJson = (json['subjectScores'] as Map<String, dynamic>?) ?? const {};
    final subjectScores = <String, SubjectScore>{};
    scoresJson.forEach((key, value) {
      final v = value as Map<String, dynamic>;
      subjectScores[key] = SubjectScore(
        name: v['name'] as String,
        totalQuestions: v['totalQuestions'] as int,
        correctCount: v['correctCount'] as int,
      );
    });

    return ExamResult(
      totalQuestions: json['totalQuestions'] as int,
      correctCount: json['correctCount'] as int,
      elapsedTime: Duration(seconds: json['elapsedSeconds'] as int),
      isPassed: json['isPassed'] as bool,
      subjectScores: subjectScores,
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final list = await _api.get('/study/mock-exams/history', query: {
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
    }) as List;
    return list.cast<Map<String, dynamic>>();
  }
}
