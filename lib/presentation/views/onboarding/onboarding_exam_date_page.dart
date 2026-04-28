import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class OnboardingExamDatePage extends StatefulWidget {
  const OnboardingExamDatePage({super.key});

  @override
  State<OnboardingExamDatePage> createState() => _OnboardingExamDatePageState();
}

class _OnboardingExamDatePageState extends State<OnboardingExamDatePage> {
  DateTime? _examDate;
  bool _noFixedDate = false;

  String get _certificateId =>
      (Get.arguments as Map<String, dynamic>?)?['certificateId'] as String? ??
      '1';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        _examDate = picked;
        _noFixedDate = false;
      });
    }
  }

  String? get _dateLabel {
    if (_noFixedDate) return '정해진 일정 없음';
    if (_examDate == null) return null;
    return '${_examDate!.year}년 ${_examDate!.month}월 ${_examDate!.day}일';
  }

  bool get _canContinue => _examDate != null || _noFixedDate;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.08;

    return Scaffold(
      backgroundColor: colors.gray10,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        leading: Semantics(
          button: true,
          identifier: 'onboarding-back',
          label: '뒤로 가기',
          child: IconButton(
            icon: Assets.icons.arrowBackIos.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: _buildProgressBar(colors, screenWidth, 0.5),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '언제까지 합격하고 싶은지 알려주세요',
                    style: Typo.headingStrong(context, color: colors.gray900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '시험 일정에 맞춰 커리큘럼을 생성할게요.',
                    style: Typo.labelRegular(context, color: colors.gray300),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: (_examDate != null && !_noFixedDate)
                            ? colors.primaryLight
                            : colors.gray0,
                        border: Border.all(
                          color: (_examDate != null && !_noFixedDate)
                              ? colors.primaryNormal
                              : colors.gray900,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _examDate != null && !_noFixedDate
                            ? _dateLabel!
                            : '날짜 선택하기',
                        style: Typo.bodyRegular(context, color: colors.gray900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      _noFixedDate = true;
                      _examDate = null;
                    }),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: _noFixedDate ? colors.primaryLight : colors.gray0,
                        border: Border.all(
                          color: _noFixedDate
                              ? colors.primaryNormal
                              : colors.gray900,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '정해진 일정 없음',
                        style: Typo.bodyRegular(context, color: colors.gray900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 32),
            child: CustomButton(
              text: '계속하기',
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: !_canContinue,
              width: double.infinity,
              onPressed: !_canContinue
                  ? null
                  : () => Get.toNamed(
                        AppRoutes.onboardingHours,
                        arguments: {
                          'certificateId': _certificateId,
                          'examDate': _noFixedDate
                              ? null
                              : _examDate!.toIso8601String(),
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      ThemeColors colors, double screenWidth, double progress) {
    final maxWidth = screenWidth - 15 - 56;
    return Container(
      height: 12,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: maxWidth * progress,
            height: 12,
            decoration: BoxDecoration(
              color: colors.primaryNormal,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
