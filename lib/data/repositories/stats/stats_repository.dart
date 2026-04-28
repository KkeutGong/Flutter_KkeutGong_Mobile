import 'package:kkeutgong_mobile/core/api/api_client.dart';

class StatsRepository {
  StatsRepository._internal();
  static final StatsRepository _instance = StatsRepository._internal();
  factory StatsRepository() => _instance;

  final ApiClient _api = ApiClient();

  Future<int> getPasserCount() async {
    final json = await _api.get('/stats/passers') as Map<String, dynamic>;
    return (json['count'] as num).toInt();
  }
}
