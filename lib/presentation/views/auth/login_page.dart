import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/data/repositories/auth/auth_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/stats/stats_repository.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthRepository _auth = AuthRepository();
  final StatsRepository _stats = StatsRepository();
  bool _isLoading = false;
  int? _passerCount;

  @override
  void initState() {
    super.initState();
    _loadPasserCount();
  }

  Future<void> _loadPasserCount() async {
    try {
      final count = await _stats.getPasserCount();
      if (mounted) setState(() => _passerCount = count);
    } catch (_) {
      // Background fetch — failure just leaves the placeholder visible.
    }
  }

  Future<void> _loginWithKakao() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _auth.loginWithKakao();
      if (!mounted) return;
      await _afterLogin(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인에 실패했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _auth.loginWithGoogle();
      if (!mounted) return;
      await _afterLogin(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _auth.loginWithApple();
      if (!mounted) return;
      await _afterLogin(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple 로그인에 실패했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _afterLogin(AuthResult auth) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Pending onboarding data (collected on the welcome flow before login)
    // takes priority — apply it and route to main.
    final certId = prefs.getString('pending_onboarding_certificateId');
    if (certId != null) {
      await _applyPendingOnboarding(prefs, certId);
      return;
    }

    // Brand-new accounts: stop at the nickname confirmation screen before
    // onboarding so users don't end up stuck with the auto-filled name from
    // their social provider (e.g. '끝공 수험생' for Kakao without nickname scope).
    if (auth.isNewUser) {
      Get.offAllNamed(
        AppRoutes.profileSetup,
        arguments: {'nickname': auth.nickname},
      );
      return;
    }

    // No pending data: server is the source of truth. An existing user
    // logging in on a fresh install has has_onboarded=false locally but
    // already has certificates registered server-side, so they must skip
    // onboarding instead of being looped back into it.
    final hadOnboarded = prefs.getBool('has_onboarded') ?? false;
    final hasCerts = await _hasUserCertificates(fallback: hadOnboarded);
    if (!mounted) return;
    if (hasCerts) {
      await prefs.setBool('has_onboarded', true);
      Get.offAllNamed(AppRoutes.main);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  // Maps the Korean label saved during onboarding step 4 to the enum the
  // backend understands. Returns null when the user skipped this step.
  String? _mapStyleTextToEnum(String? styleText) {
    switch (styleText) {
      case '빠른 문제 풀이':
        return 'fast';
      case '개념 위주':
        return 'concept';
      case '해설 위주':
        return 'explanation';
      case '반복 학습':
        return 'repetition';
      default:
        return null;
    }
  }

  Future<bool> _hasUserCertificates({required bool fallback}) async {
    try {
      final api = ApiClient();
      final result = await api.get('/users/me/certificates') as List;
      return result.isNotEmpty;
    } catch (_) {
      // Onboarded users keep their session; fresh installs default to
      // onboarding so brand-new accounts aren't pushed straight to main on a
      // transient network error.
      return fallback;
    }
  }

  Future<void> _applyPendingOnboarding(
      SharedPreferences prefs, String certId) async {
    final api = ApiClient();
    try {
      // Register certificate for this user first
      await api.post('/users/me/certificates', body: {'certificateId': certId});
    } catch (_) {
      // Best-effort — proceed even if already registered
    }
    try {
      final examDate = prefs.getString('pending_onboarding_examDate');
      final examSessionId = prefs.getString('pending_onboarding_examSessionId');
      final hoursPerWeek = prefs.getInt('pending_onboarding_hoursPerWeek') ?? 7;
      final styleText = prefs.getString('pending_onboarding_style');
      final studyStyle = _mapStyleTextToEnum(styleText);
      final body = <String, dynamic>{
        'certificateId': certId,
        'hoursPerWeek': hoursPerWeek,
        if (examDate != null) 'examDate': examDate,
        if (examSessionId != null) 'examSessionId': examSessionId,
        if (studyStyle != null) 'studyStyle': studyStyle,
      };
      await api.post('/curricula/generate', body: body);
    } catch (_) {
      // Ignore curriculum generation errors — still mark onboarded
    }
    await prefs.setBool('has_onboarded', true);
    // Clean up pending keys
    await prefs.remove('pending_onboarding_certificateId');
    await prefs.remove('pending_onboarding_examDate');
    await prefs.remove('pending_onboarding_examSessionId');
    await prefs.remove('pending_onboarding_hoursPerWeek');
    await prefs.remove('pending_onboarding_style');
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isIOS = !kIsWeb && Platform.isIOS;

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.088),
          child: Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  Text(
                    '끝공으로 합격한 합격자 수',
                    textAlign: TextAlign.center,
                    style: Typo.bodyRegular(context).copyWith(color: colors.gray900),
                  ),
                  Text(
                    _passerCount != null
                        ? NumberFormat.decimalPattern('en_US').format(_passerCount)
                        : '—',
                    textAlign: TextAlign.center,
                    style: Typo.displayStrong(context),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Semantics(
                    button: true,
                    identifier: 'login-kakao',
                    label: '카카오로 시작하기',
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isLoading ? '로그인 중…' : '카카오로 시작하기',
                        theme: CustomButtonTheme.grayscale,
                        size: ButtonSize.large,
                        backgroundColor: const Color(0xFFFEE500),
                        textColor: colors.gray900,
                        leftIcon: Assets.icons.kakaoLogo,
                        onPressed: _isLoading ? null : _loginWithKakao,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  Semantics(
                    button: true,
                    identifier: 'login-google',
                    label: '구글로 시작하기',
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isLoading ? '로그인 중…' : '구글로 시작하기',
                        theme: CustomButtonTheme.grayscale,
                        size: ButtonSize.large,
                        backgroundColor: colors.gray0,
                        textColor: colors.gray900,
                        leftIcon: Assets.icons.googleLogo,
                        useDefaultIconColor: true,
                        onPressed: _isLoading ? null : _loginWithGoogle,
                      ),
                    ),
                  ),
                  if (isIOS) ...[
                    SizedBox(height: screenHeight * 0.012),
                    Semantics(
                      button: true,
                      identifier: 'login-apple',
                      label: 'Apple로 시작하기',
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isLoading ? '로그인 중…' : 'Apple로 시작하기',
                          theme: CustomButtonTheme.grayscale,
                          size: ButtonSize.large,
                          backgroundColor: colors.gray900,
                          textColor: colors.gray0,
                          leftIcon: Assets.icons.appleLogo,
                          onPressed: _isLoading ? null : _loginWithApple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: screenHeight * 0.045),
            ],
          ),
        ),
      ),
    );
  }
}
