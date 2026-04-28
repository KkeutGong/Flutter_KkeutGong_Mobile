import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/domain/models/user/user_certificate.dart';

class UserCertificatesRepository {
  static final UserCertificatesRepository _instance =
      UserCertificatesRepository._internal();
  factory UserCertificatesRepository() => _instance;
  UserCertificatesRepository._internal();

  final ApiClient _api = ApiClient();

  Future<List<UserCertificate>> getMyCertificates() async {
    final list = await _api.get('/users/me/certificates') as List;
    return list
        .map((e) => UserCertificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCertificate(String certificateId) async {
    await _api.post(
      '/users/me/certificates',
      body: {'certificateId': certificateId},
    );
  }

  Future<void> setActive(String certificateId) async {
    await _api.patch(
      '/users/me/certificates/active',
      body: {'certificateId': certificateId},
    );
  }

  Future<void> remove(String certificateId) async {
    await _api.delete('/users/me/certificates/$certificateId');
  }
}
