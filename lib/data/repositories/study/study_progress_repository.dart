import 'package:shared_preferences/shared_preferences.dart';

class StudyProgressRepository {
  static const String _practicePrefix = 'practice_progress_';
  static const String _conceptPrefix = 'concept_progress_';
  static const String _overallKey = 'overall_progress';

  Future<void> savePracticeProgress({required String subjectName, required int currentIndex, required int total, required int answeredCount}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_practicePrefix${subjectName}_index', currentIndex);
    await prefs.setInt('$_practicePrefix${subjectName}_total', total);
    await prefs.setInt('$_practicePrefix${subjectName}_answered', answeredCount);
    final percent = total > 0 ? ((answeredCount) / total).clamp(0.0, 1.0) : 0.0;
    await _updateOverallProgress(prefs, subjectName, percent);
  }

  Future<void> savePracticeAnswers({required String subjectName, required Map<String, int> answers}) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = answers.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('$_practicePrefix${subjectName}_answers', serialized);
  }

  Future<Map<String, int>> getPracticeAnswers(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_practicePrefix${subjectName}_answers') ?? const <String>[];
    final map = <String, int>{};
    for (final item in list) {
      final sep = item.indexOf(':');
      if (sep > 0) {
        final id = item.substring(0, sep);
        final valStr = item.substring(sep + 1);
        final val = int.tryParse(valStr);
        if (val != null) map[id] = val;
      }
    }
    return map;
  }

  Future<void> saveConceptProgress({required String subjectName, required int knownCount, required int total}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_conceptPrefix${subjectName}_known', knownCount);
    await prefs.setInt('$_conceptPrefix${subjectName}_total', total);
    final percent = total > 0 ? (knownCount / total).clamp(0.0, 1.0) : 0.0;
    await _updateOverallProgress(prefs, subjectName, percent);
  }

  Future<void> saveConceptKnownIds({required String subjectName, required List<String> knownIds}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_conceptPrefix${subjectName}_known_ids', knownIds);
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

  /// 특정 subject의 concept + practice 평균 진행률
  Future<double> getSubjectProgress(String subjectName) async {
    final concept = await getConceptPercent(subjectName);
    final practice = await getPracticePercent(subjectName);
    // concept과 practice 각각 50%씩 (review는 별도)
    return (concept + practice) / 2.0;
  }

  /// 전체 subjects에 대한 진행률 계산 (subjects 목록 기준)
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

  /// 모든 학습 진행 상황을 초기화합니다.
  /// - practice: index, total, answered, answers
  /// - concept: total, known, known_ids
  /// - overall: per-subject overall_* 및 overall_progress
  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();

    for (final key in keys) {
      // Practice 관련 모든 키 삭제
      if (key.startsWith(_practicePrefix)) {
        await prefs.remove(key);
        continue;
      }
      // Concept 관련 모든 키 삭제
      if (key.startsWith(_conceptPrefix)) {
        await prefs.remove(key);
        continue;
      }
      // Overall 관련 키 삭제
      if (key.startsWith('overall_')) {
        await prefs.remove(key);
        continue;
      }
    }

    await prefs.remove(_overallKey);
  }

  /// 이전 버전 호환용 (deprecated, use resetAllProgress instead)
  Future<void> resetAllPercents() async {
    await resetAllProgress();
  }

  Future<void> _updateOverallProgress(SharedPreferences prefs, String subjectName, double percent) async {
    // 각 subject의 concept과 practice 진행률을 별도로 저장하고 평균 계산
    // concept: concept_progress_{subject}_known / concept_progress_{subject}_total
    // practice: practice_progress_{subject}_answered / practice_progress_{subject}_total
    // 전체 진행률 = 모든 subject의 (concept + practice) / 2의 평균
    
    // 현재 저장된 모든 subject의 진행률 계산
    final allKeys = prefs.getKeys();
    final subjectNames = <String>{};
    
    for (final key in allKeys) {
      if (key.startsWith(_conceptPrefix) && key.endsWith('_total')) {
        final name = key.substring(_conceptPrefix.length, key.length - '_total'.length);
        subjectNames.add(name);
      }
      if (key.startsWith(_practicePrefix) && key.endsWith('_total')) {
        final name = key.substring(_practicePrefix.length, key.length - '_total'.length);
        subjectNames.add(name);
      }
    }
    
    if (subjectNames.isEmpty) {
      await prefs.setDouble(_overallKey, 0.0);
      return;
    }
    
    double totalProgress = 0.0;
    for (final name in subjectNames) {
      final conceptTotal = prefs.getInt('$_conceptPrefix${name}_total') ?? 0;
      final conceptKnown = prefs.getInt('$_conceptPrefix${name}_known') ?? 0;
      final conceptPercent = conceptTotal > 0 ? conceptKnown / conceptTotal : 0.0;
      
      final practiceTotal = prefs.getInt('$_practicePrefix${name}_total') ?? 0;
      final practiceAnswered = prefs.getInt('$_practicePrefix${name}_answered') ?? 0;
      final practicePercent = practiceTotal > 0 ? practiceAnswered / practiceTotal : 0.0;
      
      // subject별 평균 (concept 50% + practice 50%)
      totalProgress += (conceptPercent + practicePercent) / 2.0;
    }
    
    final overall = totalProgress / subjectNames.length;
    await prefs.setDouble(_overallKey, overall.clamp(0.0, 1.0));
  }
}
