import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/auth/token_store.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String nickname;
  // True when the backend created a brand-new account on this login. Used to
  // route into the post-signup nickname confirmation step.
  final bool isNewUser;
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.nickname,
    required this.isNewUser,
  });
}

class AuthRepository {
  AuthRepository._internal();
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;

  final ApiClient _api = ApiClient();
  final TokenStore _tokenStore = TokenStore();
  final Session _session = Session();

  // ── Kakao ──────────────────────────────────────────────────────────────────

  Future<AuthResult> loginWithKakao() async {
    OAuthToken token;
    try {
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } catch (e) {
      // Fall back to KakaoAccount if KakaoTalk login fails (e.g. user cancels app switch)
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    return _serverLogin(provider: 'kakao', providerToken: token.accessToken);
  }

  // ── Google ─────────────────────────────────────────────────────────────────

  Future<AuthResult> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('Google 로그인이 취소되었습니다.');
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Google ID 토큰을 가져올 수 없습니다.');
    return _serverLogin(provider: 'google', providerToken: idToken);
  }

  // ── Apple ──────────────────────────────────────────────────────────────────

  Future<AuthResult> loginWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Apple ID 토큰을 가져올 수 없습니다.');
    final nickname = credential.givenName != null
        ? '${credential.givenName} ${credential.familyName ?? ''}'.trim()
        : null;
    return _serverLogin(
      provider: 'apple',
      providerToken: idToken,
      nickname: nickname,
    );
  }

  // ── Logout / Delete ────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final refresh = await _tokenStore.refreshToken;
      if (refresh != null) {
        await _api.post('/auth/logout', body: {'refreshToken': refresh});
      }
    } catch (_) {
      // Best-effort server logout; always clear local tokens.
    } finally {
      await _tokenStore.clear();
      _session.userId = '';
    }
  }

  Future<void> deleteAccount() async {
    await _api.delete('/users/me');
    await _tokenStore.clear();
    _session.userId = 'demo-user';
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<AuthResult> _serverLogin({
    required String provider,
    required String providerToken,
    String? nickname,
  }) async {
    final json = await _api.postRaw('/auth/social-login', body: {
      'provider': provider,
      'providerToken': providerToken,
      if (nickname != null) 'nickname': nickname,
    }) as Map<String, dynamic>;

    final user = json['user'] as Map<String, dynamic>;
    final result = AuthResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: user['id'] as String,
      nickname: user['nickname'] as String,
      isNewUser: (json['isNewUser'] as bool?) ?? false,
    );
    await _tokenStore.saveTokens(
      access: result.accessToken,
      refresh: result.refreshToken,
    );
    _session.userId = result.userId;
    return result;
  }
}
