import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/exam_session.dart';

class CatalogRepository {
  CatalogRepository._internal();
  static final CatalogRepository _instance = CatalogRepository._internal();
  factory CatalogRepository() => _instance;

  final ApiClient _api = ApiClient();

  // Cached for the lifetime of the app — the certificate catalog is small
  // and rarely changes, so we don't want to refetch on every onboarding step.
  List<Certificate>? _certificatesCache;

  Future<List<Certificate>> getCertificates({bool forceRefresh = false}) async {
    if (!forceRefresh && _certificatesCache != null) {
      return _certificatesCache!;
    }
    final json = await _api.get('/catalog/certificates') as List;
    final list = json
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList();
    _certificatesCache = list;
    return list;
  }

  // Exam sessions change as new sittings are announced, so we refetch on each
  // onboarding visit rather than caching like the certificate list.
  Future<List<ExamSession>> getExamSessions(String certificateId) async {
    final json = await _api
        .get('/catalog/certificates/$certificateId/exam-sessions') as List;
    return json
        .map((e) => ExamSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
