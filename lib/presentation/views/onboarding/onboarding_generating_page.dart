import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class OnboardingGeneratingPage extends StatefulWidget {
  const OnboardingGeneratingPage({super.key});

  @override
  State<OnboardingGeneratingPage> createState() =>
      _OnboardingGeneratingPageState();
}

class _OnboardingGeneratingPageState extends State<OnboardingGeneratingPage> {
  final ApiClient _api = ApiClient();
  bool _hasError = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Map<String, dynamic> get _args =>
      (Get.arguments as Map<String, dynamic>?) ?? {};

  Future<void> _generate() async {
    setState(() {
      _hasError = false;
      _isRetrying = true;
    });
    try {
      final body = {
        'certificateId': _args['certificateId'] ?? '1',
        'hoursPerWeek': _args['hoursPerWeek'] ?? 7,
        if (_args['examDate'] != null) 'examDate': _args['examDate'],
        if (_args['examSessionId'] != null)
          'examSessionId': _args['examSessionId'],
        if (_args['studyStyle'] != null) 'studyStyle': _args['studyStyle'],
        if (_args['weekendMultiplier'] != null)
          'weekendMultiplier': _args['weekendMultiplier'],
      };
      await _api.post('/curricula/generate', body: body);
      // Only mark the user as onboarded once the curriculum actually exists,
      // so a transient backend failure doesn't strand them on a blank home.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_onboarded', true);
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.main);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.gray10,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: _hasError
                ? _buildErrorState(colors)
                : _buildLoadingState(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: colors.primaryNormal),
        const SizedBox(height: 24),
        Text(
          'AI가 커리큘럼을 생성하고 있어요',
          style: Typo.titleStrong(context, color: colors.gray900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '잠시만 기다려 주세요',
          style: Typo.bodyRegular(context, color: colors.gray600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 56, color: colors.gray500),
        const SizedBox(height: 20),
        Text(
          '커리큘럼을 만들지 못했어요',
          style: Typo.titleStrong(context, color: colors.gray900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '네트워크 상태를 확인하고 다시 시도해 주세요.',
          style: Typo.bodyRegular(context, color: colors.gray500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: _isRetrying ? '다시 시도 중…' : '다시 시도',
            size: ButtonSize.large,
            theme: CustomButtonTheme.primary,
            disabled: _isRetrying,
            onPressed: _isRetrying ? null : _generate,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isRetrying ? null : () => Get.back(),
          child: Text(
            '이전 단계로',
            style: Typo.bodyRegular(context, color: colors.gray500),
          ),
        ),
      ],
    );
  }
}
