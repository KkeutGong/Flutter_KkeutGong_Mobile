import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/data/repositories/auth/auth_repository.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthRepository _auth = AuthRepository();
  bool _isLoading = false;

  Future<void> _loginWithKakao() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _auth.loginWithKakao();
      if (!mounted) return;
      await _afterLogin();
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
      await _auth.loginWithGoogle();
      if (!mounted) return;
      await _afterLogin();
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
      await _auth.loginWithApple();
      if (!mounted) return;
      await _afterLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple 로그인에 실패했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _afterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    if (!mounted) return;
    if (hasOnboarded) {
      // Check if user actually has certificates registered
      final hasCerts = await _hasUserCertificates();
      if (!mounted) return;
      if (hasCerts) {
        Get.offAllNamed(AppRoutes.main);
      } else {
        Get.offAllNamed(AppRoutes.onboarding);
      }
    } else {
      // Check for pending onboarding data saved before login
      final certId = prefs.getString('pending_onboarding_certificateId');
      if (certId != null) {
        await _applyPendingOnboarding(prefs, certId);
      } else {
        Get.offAllNamed(AppRoutes.onboarding);
      }
    }
  }

  Future<bool> _hasUserCertificates() async {
    try {
      final api = ApiClient();
      final result = await api.get('/users/me/certificates') as List;
      return result.isNotEmpty;
    } catch (_) {
      return true; // Assume has certs on error to avoid redirect loop
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
      final hoursPerWeek = prefs.getInt('pending_onboarding_hoursPerWeek') ?? 7;
      final body = <String, dynamic>{
        'certificateId': certId,
        'hoursPerWeek': hoursPerWeek,
        if (examDate != null) 'examDate': examDate,
      };
      await api.post('/curricula/generate', body: body);
    } catch (_) {
      // Ignore curriculum generation errors — still mark onboarded
    }
    await prefs.setBool('has_onboarded', true);
    // Clean up pending keys
    await prefs.remove('pending_onboarding_certificateId');
    await prefs.remove('pending_onboarding_examDate');
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
                    '끝공',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -1.4,
                      color: colors.primaryNormal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '포기하지 않는 경험을 만듭니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: -0.4,
                      color: colors.gray500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '합격자 수',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.primaryDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '102,870,965',
                          style: TextStyle(
                            fontFamily: 'SeoulAlrim',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: colors.primaryNormal,
                          ),
                        ),
                      ],
                    ),
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
