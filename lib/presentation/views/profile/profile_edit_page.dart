import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/data/repositories/user/user_repository.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

/// Settings → "프로필 편집". Lets a logged-in user change their nickname.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _userRepo = UserRepository();
  late final TextEditingController _controller;
  bool _loading = true;
  bool _saving = false;
  String _initialNickname = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final me = await _userRepo.getMe(Session().userId);
      if (!mounted) return;
      setState(() {
        _initialNickname = me.nickname;
        _controller.text = me.nickname;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canSave {
    final v = _controller.text.trim();
    return !_saving && v.isNotEmpty && v.length <= 20 && v != _initialNickname;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _userRepo.updateNickname(Session().userId, _controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임이 변경되었어요.')),
      );
      Get.back(result: true);
    } catch (_) {
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
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        leading: IconButton(
          icon: Assets.icons.arrowBackIos.svg(
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('프로필 편집', style: Typo.headingRegular(context, color: colors.gray900)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '닉네임',
                      style: Typo.labelStrong(context, color: colors.gray600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLength: 20,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
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
                      Text(_error!, style: Typo.labelRegular(context, color: Colors.red)),
                    ],
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: CustomButton(
                        text: _saving ? '저장 중…' : '저장',
                        size: ButtonSize.large,
                        theme: CustomButtonTheme.primary,
                        width: double.infinity,
                        disabled: !_canSave,
                        onPressed: _canSave ? _save : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
