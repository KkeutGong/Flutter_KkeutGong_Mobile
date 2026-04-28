import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/domain/models/study/study_card.dart';

class ConceptStudyRepository {
  static final ConceptStudyRepository _instance = ConceptStudyRepository._internal();
  factory ConceptStudyRepository() => _instance;
  ConceptStudyRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  final Map<String, List<StudyCard>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  Future<List<StudyCard>> getStudyCards(String subjectName, {bool forceRefresh = false}) async {
    final cacheKey = '${_session.currentCertificateId}/$subjectName';
    if (forceRefresh) {
      _cache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    }
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      for (final c in _cache[cacheKey]!) {
        c.isKnown = false;
      }
      return _cache[cacheKey]!;
    }

    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) {
      throw StateError('subjectId for "$subjectName" is unknown — load home first');
    }

    final list = await _api.get('/study/concepts', query: {
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
      'subjectId': subjectId,
    }) as List;

    final cards = list
        .map((e) => StudyCard.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache[cacheKey] = cards;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return cards;
  }

  Future<void> updateCardFavorite(String cardId, bool isFavorite) async {
    // Persisted in bulk via saveProgress — no per-card backend call needed.
  }

  Future<void> updateCardKnown(String cardId, bool isKnown) async {
    // Persisted in bulk via saveProgress.
  }

  Future<void> saveProgress({
    required String subjectName,
    required List<String> knownIds,
    required List<String> favoriteIds,
  }) async {
    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) return;
    // Ensure both are always JSON arrays, never objects/sets.
    await _api.post('/study/concepts/progress', body: {
      'userId': _session.userId,
      'certificateId': _session.currentCertificateId,
      'subjectId': subjectId,
      'knownIds': List<String>.from(knownIds),
      'favoriteIds': List<String>.from(favoriteIds),
    });
  }

  void invalidateCache(String subjectName) {
    final key = '${_session.currentCertificateId}/$subjectName';
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
