import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';

class PassTrendPoint {
  final DateTime date;
  final int value;

  const PassTrendPoint({required this.date, required this.value});

  factory PassTrendPoint.fromJson(Map<String, dynamic> json) =>
      PassTrendPoint(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        value: (json['value'] as num?)?.toInt() ?? 0,
      );
}

/// Lazy fetch for the pass-likelihood trend chart shown inside the home
/// tab's bottom sheet. The endpoint is cheap (last-30 selects) so we
/// don't bother caching here — caller controls the lifecycle.
class PassTrendRepository {
  static final PassTrendRepository _instance = PassTrendRepository._internal();
  factory PassTrendRepository() => _instance;
  PassTrendRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  Future<List<PassTrendPoint>> getTrend({int limit = 30}) async {
    final list = await _api.get('/study/pass-trend', query: {
      'certificateId': _session.currentCertificateId,
      'limit': limit.toString(),
    }) as List;
    return list
        .map((e) => PassTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
