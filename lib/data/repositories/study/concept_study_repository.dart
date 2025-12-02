import 'package:kkeutgong_mobile/domain/models/study/study_card.dart';

class ConceptStudyRepository {
  static final ConceptStudyRepository _instance = ConceptStudyRepository._internal();
  factory ConceptStudyRepository() => _instance;
  ConceptStudyRepository._internal();

  final Map<String, List<StudyCard>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool _isCacheValid(String subjectName) {
    final timestamp = _cacheTimestamps[subjectName];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  Future<List<StudyCard>> getStudyCards(String subjectName, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cache.remove(subjectName);
      _cacheTimestamps.remove(subjectName);
    }

    if (_cache.containsKey(subjectName) && _isCacheValid(subjectName)) {
      for (var card in _cache[subjectName]!) {
        card.isKnown = false;
      }
      return _cache[subjectName]!;
    }

    final cards = List.generate(
      10,
      (index) => StudyCard(
        id: 'card_$index',
        question: '정적인 자료구조로\n기억장소의 추가가 어렵고\n메모리의 낭비가 발생함 $index',
        answer: '배열',
      ),
    );

    _cache[subjectName] = cards;
    _cacheTimestamps[subjectName] = DateTime.now();

    return cards;
  }

  Future<void> updateCardFavorite(String cardId, bool isFavorite) async {
  }

  Future<void> updateCardKnown(String cardId, bool isKnown) async {
  }

  Future<void> saveProgress(String subjectName, int currentIndex, int totalCards) async {
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
