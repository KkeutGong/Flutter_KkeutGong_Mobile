import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';

class HomeRepository {
  static final HomeRepository _instance = HomeRepository._internal();
  factory HomeRepository() => _instance;
  HomeRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  HomeData? _cache;
  DateTime? _cacheTimestamp;
  String? _cachedCertificateId;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_cache == null || _cacheTimestamp == null || _cachedCertificateId == null) return false;
    if (_cachedCertificateId != _session.currentCertificateId) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry;
  }

  Future<HomeData> getHomeData({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cache!;
    }

    // userId comes from the JWT subject server-side. Sending it as a query
    // would let a stale Session value leak into the request.
    final json = await _api.get('/home', query: {
      'certificateId': _session.currentCertificateId,
    }) as Map<String, dynamic>;

    final homeData = HomeData.fromJson(json);
    _session.rememberSubjects(
      homeData.subjects.map((s) => (id: s.id, name: s.name)),
    );

    _cache = homeData;
    _cacheTimestamp = DateTime.now();
    _cachedCertificateId = _session.currentCertificateId;

    return homeData;
  }

  void setCurrentCertificate(String certificateId) {
    _session.currentCertificateId = certificateId;
    invalidateCache();
  }

  void invalidateCache() {
    _cache = null;
    _cacheTimestamp = null;
    _cachedCertificateId = null;
  }
}
