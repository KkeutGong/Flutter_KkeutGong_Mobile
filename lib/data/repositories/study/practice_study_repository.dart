import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';

class PracticeStudyRepository {
  static final PracticeStudyRepository _instance = PracticeStudyRepository._internal();
  factory PracticeStudyRepository() => _instance;
  PracticeStudyRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  final Map<String, List<Question>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool _isCacheValid(String key) {
    final ts = _cacheTimestamps[key];
    if (ts == null) return false;
    return DateTime.now().difference(ts) < _cacheExpiry;
  }

  Future<List<Question>> getQuestions(String subjectName, {bool forceRefresh = false}) async {
    final key = '${_session.currentCertificateId}/$subjectName';
    if (!forceRefresh && _cache.containsKey(key) && _isCacheValid(key)) {
      return _cache[key]!;
    }

    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) {
      throw StateError('subjectId for "$subjectName" is unknown — load home first');
    }

    final list = await _api.get('/study/practice', query: {
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
      'subjectId': subjectId,
    }) as List;

    final questions = list
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache[key] = questions;
    _cacheTimestamps[key] = DateTime.now();
    return questions;
  }

  Future<void> saveAnswers({
    required String subjectName,
    required Map<String, int> answers,
  }) async {
    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) return;
    await _api.post('/study/practice/progress', body: {
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
      'subjectId': subjectId,
      'answers': answers,
    });
  }

  void invalidateCache(String subjectName) {
    _cache.remove('${_session.currentCertificateId}/$subjectName');
    _cacheTimestamps.remove('${_session.currentCertificateId}/$subjectName');
  }

  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
