import 'package:kkeutgong_mobile/core/api/api_client.dart';

class UserProfile {
  final String id;
  final String nickname;
  final DateTime joinedAt;

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.joinedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );
}

class UserRepository {
  UserRepository._internal();
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;

  final ApiClient _api = ApiClient();

  Future<UserProfile> getMe(String userId) async {
    final json = await _api.get('/users/$userId') as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> updateNickname(String userId, String nickname) async {
    final json = await _api.patch(
      '/users/$userId',
      body: {'nickname': nickname},
    ) as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }
}
