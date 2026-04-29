import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/data/repositories/study/concept_study_repository.dart'
    show StudyScope;
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

  Future<List<Question>> getQuestions(
    String subjectName, {
    bool forceRefresh = false,
    StudyScope scope = StudyScope.today,
    int extra = 0,
  }) async {
    final key = '${_session.currentCertificateId}/$subjectName/${scope.name}-$extra';
    if (!forceRefresh && _cache.containsKey(key) && _isCacheValid(key)) {
      return _cache[key]!;
    }

    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) {
      throw StateError('subjectId for "$subjectName" is unknown — load home first');
    }

    final query = <String, String>{
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
      'subjectId': subjectId,
      'scope': scope.name,
    };
    if (extra > 0) query['extra'] = extra.toString();

    final list = await _api.get('/study/practice', query: query) as List;

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
    final prefix = '${_session.currentCertificateId}/$subjectName/';
    _cache.removeWhere((k, _) => k.startsWith(prefix));
    _cacheTimestamps.removeWhere((k, _) => k.startsWith(prefix));
  }

  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
