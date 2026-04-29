import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/domain/models/study/today_plan.dart';

/// Thin wrapper around GET /study/today. Cached for 30s so the home and
/// curriculum tabs can both read it without hammering the backend, and
/// invalidated as soon as a study session completes (the caller is
/// expected to call [invalidate] after navigating back from a study screen).
class TodayRepository {
  static final TodayRepository _instance = TodayRepository._internal();
  factory TodayRepository() => _instance;
  TodayRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  TodayPlan? _cache;
  String? _cacheKey;
  DateTime? _cacheAt;
  static const _expiry = Duration(seconds: 30);

  Future<TodayPlan> getToday({bool forceRefresh = false}) async {
    final certId = _session.currentCertificateId;
    final key = '${_session.userId}/$certId';
    if (!forceRefresh &&
        _cache != null &&
        _cacheKey == key &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _expiry) {
      return _cache!;
    }
    final body = await _api.get('/study/today', query: {
      'certificateId': certId,
    });
    final plan = TodayPlan.fromJson(body as Map<String, dynamic>);
    _cache = plan;
    _cacheKey = key;
    _cacheAt = DateTime.now();
    return plan;
  }

  void invalidate() {
    _cache = null;
    _cacheKey = null;
    _cacheAt = null;
  }
}
