import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-cache mirror of progress for instant UI reads, with backend as source of truth.
class StudyProgressRepository {
  StudyProgressRepository();

  static const String _practicePrefix = 'practice_progress_';
  static const String _conceptPrefix = 'concept_progress_';
  static const String _overallKey = 'overall_progress';

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  Future<void> savePracticeProgress({
    required String subjectName,
    required int currentIndex,
    required int total,
    required int answeredCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_practicePrefix${subjectName}_index', currentIndex);
    await prefs.setInt('$_practicePrefix${subjectName}_total', total);
    await prefs.setInt('$_practicePrefix${subjectName}_answered', answeredCount);
    final percent = total > 0 ? (answeredCount / total).clamp(0.0, 1.0) : 0.0;
    await _updateOverallProgress(prefs, subjectName, percent);
  }

  Future<void> savePracticeAnswers({
    required String subjectName,
    required Map<String, int> answers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = answers.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('$_practicePrefix${subjectName}_answers', serialized);

    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) return;
    try {
      await _api.post('/study/practice/progress', body: {
        'userId': _session.userId,
        'certificateId': _session.currentCertificateId,
        'subjectId': subjectId,
        'answers': answers,
      });
    } catch (_) {
      // network failure: keep local copy, retry on next save
    }
  }

  Future<Map<String, int>> getPracticeAnswers(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_practicePrefix${subjectName}_answers') ?? const <String>[];
    final map = <String, int>{};
    for (final item in list) {
      final sep = item.indexOf(':');
      if (sep > 0) {
        final id = item.substring(0, sep);
        final val = int.tryParse(item.substring(sep + 1));
        if (val != null) map[id] = val;
      }
    }
    return map;
  }

  Future<void> saveConceptProgress({
    required String subjectName,
    required int knownCount,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_conceptPrefix${subjectName}_known', knownCount);
    await prefs.setInt('$_conceptPrefix${subjectName}_total', total);
    final percent = total > 0 ? (knownCount / total).clamp(0.0, 1.0) : 0.0;
    await _updateOverallProgress(prefs, subjectName, percent);
  }

  Future<void> saveConceptKnownIds({
    required String subjectName,
    required List<String> knownIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_conceptPrefix${subjectName}_known_ids', knownIds);

    final favIds = prefs.getStringList('$_conceptPrefix${subjectName}_favorite_ids') ?? const <String>[];
    final subjectId = _session.subjectIdFor(subjectName);
    if (subjectId == null) return;
    try {
      // Ensure both are always JSON arrays, never objects/sets.
      await _api.post('/study/concepts/progress', body: {
        'userId': _session.userId,
        'certificateId': _session.currentCertificateId,
        'subjectId': subjectId,
        'knownIds': List<String>.from(knownIds),
        'favoriteIds': List<String>.from(favIds),
      });
    } catch (_) {}
  }

  Future<double> getPracticePercent(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt('$_practicePrefix${subjectName}_total') ?? 0;
    final answered = prefs.getInt('$_practicePrefix${subjectName}_answered') ?? 0;
    return total > 0 ? (answered / total) : 0.0;
  }

  Future<double> getConceptPercent(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt('$_conceptPrefix${subjectName}_total') ?? 0;
    final known = prefs.getInt('$_conceptPrefix${subjectName}_known') ?? 0;
    return total > 0 ? (known / total) : 0.0;
  }

  Future<Set<String>> getConceptKnownIds(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_conceptPrefix${subjectName}_known_ids') ?? const <String>[];
    return list.toSet();
  }

  Future<double> getOverallProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_overallKey) ?? 0.0;
  }

  Future<double> getSubjectProgress(String subjectName) async {
    final concept = await getConceptPercent(subjectName);
    final practice = await getPracticePercent(subjectName);
    return (concept + practice) / 2.0;
  }

  Future<double> calculateOverallProgress(List<String> subjectNames) async {
    if (subjectNames.isEmpty) return 0.0;
    double sum = 0.0;
    for (final name in subjectNames) {
      sum += await getSubjectProgress(name);
    }
    return sum / subjectNames.length;
  }

  Future<int> getPracticeSavedIndex(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_practicePrefix${subjectName}_index') ?? 0;
  }

  Future<int> getPracticeSavedAnswered(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_practicePrefix${subjectName}_answered') ?? 0;
  }

  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith(_practicePrefix) ||
          key.startsWith(_conceptPrefix) ||
          key.startsWith('overall_')) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_overallKey);

    try {
      await _api.post('/progress/reset', body: {
        'userId': _session.userId,
        'certificateId': _session.currentCertificateId,
      });
    } catch (_) {}
  }

  Future<void> resetAllPercents() => resetAllProgress();

  Future<void> _updateOverallProgress(SharedPreferences prefs, String subjectName, double percent) async {
    final allKeys = prefs.getKeys();
    final subjectNames = <String>{};

    for (final key in allKeys) {
      if (key.startsWith(_conceptPrefix) && key.endsWith('_total')) {
        subjectNames.add(key.substring(_conceptPrefix.length, key.length - '_total'.length));
      }
      if (key.startsWith(_practicePrefix) && key.endsWith('_total')) {
        subjectNames.add(key.substring(_practicePrefix.length, key.length - '_total'.length));
      }
    }

    if (subjectNames.isEmpty) {
      await prefs.setDouble(_overallKey, 0.0);
      return;
    }

    double totalProgress = 0.0;
    for (final name in subjectNames) {
      final cT = prefs.getInt('$_conceptPrefix${name}_total') ?? 0;
      final cK = prefs.getInt('$_conceptPrefix${name}_known') ?? 0;
      final cP = cT > 0 ? cK / cT : 0.0;
      final pT = prefs.getInt('$_practicePrefix${name}_total') ?? 0;
      final pA = prefs.getInt('$_practicePrefix${name}_answered') ?? 0;
      final pP = pT > 0 ? pA / pT : 0.0;
      totalProgress += (cP + pP) / 2.0;
    }

    final overall = totalProgress / subjectNames.length;
    await prefs.setDouble(_overallKey, overall.clamp(0.0, 1.0));
  }
}
