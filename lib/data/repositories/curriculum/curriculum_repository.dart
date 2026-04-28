import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/domain/models/curriculum/curriculum_plan.dart';

class CurriculumRepository {
  CurriculumRepository._internal();
  static final CurriculumRepository _instance = CurriculumRepository._internal();
  factory CurriculumRepository() => _instance;

  final ApiClient _api = ApiClient();

  // Returns null when the user hasn't generated a curriculum for this cert yet
  // — the curriculum_page falls back to "시험일 미정" in that case.
  Future<MyCurriculum?> getMyCurriculum(String certificateId) async {
    final result = await _api.get('/curricula/me', query: {'certificateId': certificateId});
    if (result == null) return null;
    return MyCurriculum.fromJson(result as Map<String, dynamic>);
  }
}
