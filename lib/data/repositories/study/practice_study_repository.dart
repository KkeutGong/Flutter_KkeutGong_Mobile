import 'package:kkeutgong_mobile/domain/models/study/question.dart';

class PracticeStudyRepository {
  static final PracticeStudyRepository _instance = PracticeStudyRepository._internal();
  factory PracticeStudyRepository() => _instance;
  PracticeStudyRepository._internal();

  final Map<String, List<Question>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool _isCacheValid(String subjectName) {
    final timestamp = _cacheTimestamps[subjectName];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  Future<List<Question>> getQuestions(String subjectName, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(subjectName) && _isCacheValid(subjectName)) {
      return _cache[subjectName]!;
    }


    final questions = List.generate(
      10,
      (index) => Question(
        id: 'q_$index',
        number: index + 1,
        text: '다음 중 옴의 법칙을 올바르게 나타낸 것은?',
        choices: [
          Choice(number: 1, text: 'V = IR', isCorrect: true),
          Choice(number: 2, text: 'V = I/R'),
          Choice(number: 3, text: 'V = R/I'),
          Choice(number: 4, text: 'I = VR'),
        ],
        explanation: '옴의 법칙은 V = IR로 표현됩니다. 여기서 V는 전압(볼트), I는 전류(암페어), R은 저항(옴)을 나타냅니다.',
      ),
    );

    _cache[subjectName] = questions;
    _cacheTimestamps[subjectName] = DateTime.now();

    return questions;
  }

  Future<void> saveAnswer(String questionId, int answer) async {
  }

  Future<void> saveProgress(String subjectName, int currentIndex, int totalQuestions) async {
  }

  void invalidateCache(String subjectName) {
    _cache.remove(subjectName);
    _cacheTimestamps.remove(subjectName);
  }

  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
