import 'package:package_info_plus/package_info_plus.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';

enum AppStatus { ok, forceUpdate, maintenance }

class VersionGateResult {
  final AppStatus status;
  final String? minAppVersion;
  final String? appStoreUrl;
  final String? playStoreUrl;

  const VersionGateResult({
    required this.status,
    this.minAppVersion,
    this.appStoreUrl,
    this.playStoreUrl,
  });
}

class VersionGate {
  VersionGate._();
  static final VersionGate _instance = VersionGate._();
  factory VersionGate() => _instance;

  final ApiClient _api = ApiClient();

  Future<VersionGateResult> check() async {
    try {
      final json = await _api.get('/health') as Map<String, dynamic>;
      final db = json['db'] as String? ?? 'unknown';
      if (db == 'down') {
        return const VersionGateResult(status: AppStatus.maintenance);
      }

      final minVersionStr = json['minAppVersion'] as String?;
      if (minVersionStr != null) {
        final info = await PackageInfo.fromPlatform();
        if (_isOlderThan(info.version, minVersionStr)) {
          return VersionGateResult(
            status: AppStatus.forceUpdate,
            minAppVersion: minVersionStr,
          );
        }
      }

      return const VersionGateResult(status: AppStatus.ok);
    } on ApiException catch (e) {
      if (e.statusCode == 503) {
        return const VersionGateResult(status: AppStatus.maintenance);
      }
      // Network error or other — let through to avoid blocking users.
      return const VersionGateResult(status: AppStatus.ok);
    } catch (_) {
      return const VersionGateResult(status: AppStatus.ok);
    }
  }

  /// Returns true if [current] is strictly older than [minimum].
  /// Both strings must be semver-like "X.Y.Z".
  bool _isOlderThan(String current, String minimum) {
    final c = _parse(current);
    final m = _parse(minimum);
    for (int i = 0; i < 3; i++) {
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }
    return false;
  }

  List<int> _parse(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) { parts.add(0); }
    return parts;
  }
}
