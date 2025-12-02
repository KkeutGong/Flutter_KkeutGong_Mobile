import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/domain/models/study/exam_result.dart';

class MockExamRepository {
  static final MockExamRepository _instance = MockExamRepository._internal();
  factory MockExamRepository() => _instance;
  MockExamRepository._internal();

  final Map<String, List<Question>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  bool _isCacheValid(String examName) {
    final timestamp = _cacheTimestamps[examName];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  Future<List<Question>> getQuestions(String examName, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(examName) && _isCacheValid(examName)) {
      return _cache[examName]!;
    }

    final questions = <Question>[];
    for (int i = 0; i < 100; i++) {
      questions.add(Question(
        id: 'q_$i',
        number: i + 1,
        text: '다음 중 옴의 법칙을 올바르게 나타낸 것은?',
        choices: [
          Choice(number: 1, text: 'V = IR', isCorrect: i % 4 == 0),
          Choice(number: 2, text: 'V = I/R', isCorrect: i % 4 == 1),
          Choice(number: 3, text: 'V = R/I', isCorrect: i % 4 == 2),
          Choice(number: 4, text: 'I = VR', isCorrect: i % 4 == 3),
        ],
        explanation: '옴의 법칙에 대한 해설입니다.',
      ));
    }

    _cache[examName] = questions;
    _cacheTimestamps[examName] = DateTime.now();

    return questions;
  }

  Future<void> saveAnswer(String questionId, int answer) async {
  }

  Future<void> saveExamResult(ExamResult result) async {
  }

  void invalidateCache(String examName) {
    _cache.remove(examName);
    _cacheTimestamps.remove(examName);
  }

  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
