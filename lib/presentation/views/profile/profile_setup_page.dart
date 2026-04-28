import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/data/repositories/user/user_repository.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

/// Shown right after a user signs up via social login. Lets them confirm or
/// change the auto-filled nickname before the onboarding flow begins.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _userRepo = UserRepository();
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final initial = args?['nickname'] as String? ?? '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final v = _controller.text.trim();
    return !_saving && v.isNotEmpty && v.length <= 20;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _userRepo.updateNickname(Session().userId, _controller.text.trim());
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.onboarding);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '닉네임을 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width * 0.088;

    return Scaffold(
      backgroundColor: colors.gray10,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                '어떻게\n불러드릴까요?',
                style: TextStyle(
                  fontFamily: 'SeoulAlrim',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  letterSpacing: -0.6,
                  color: colors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '학습 화면과 알림에서 사용할 닉네임이에요.',
                style: Typo.labelRegular(context, color: colors.gray300),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                maxLength: 20,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
                ],
                style: Typo.bodyRegular(context, color: colors.gray900),
                decoration: InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  filled: true,
                  fillColor: colors.gray0,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.gray30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.gray30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primaryNormal, width: 1.5),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Typo.labelRegular(context, color: Colors.red),
                ),
              ],
              const Spacer(),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: CustomButton(
                    text: _saving ? '저장 중…' : '계속하기',
                    size: ButtonSize.large,
                    theme: CustomButtonTheme.primary,
                    width: double.infinity,
                    disabled: !_canSubmit,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
