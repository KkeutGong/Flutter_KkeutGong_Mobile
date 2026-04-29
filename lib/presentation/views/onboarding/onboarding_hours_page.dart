import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

// Study time options — each maps to a hoursPerWeek value sent to the backend.
// The label / description / emoji are purely visual.
class _StudyOption {
  final String emoji;
  final String timeLabel;   // e.g. "5분"
  final String description; // e.g. "시간이 정말 부족해요"
  final int hoursPerWeek;   // value forwarded to next page

  const _StudyOption({
    required this.emoji,
    required this.timeLabel,
    required this.description,
    required this.hoursPerWeek,
  });
}

const _studyOptions = [
  _StudyOption(
    emoji: '⏱',
    timeLabel: '5분',
    description: '시간이 정말 부족해요',
    hoursPerWeek: 1,
  ),
  _StudyOption(
    emoji: '☕',
    timeLabel: '10분',
    description: '잠깐 짬내서 공부',
    hoursPerWeek: 2,
  ),
  _StudyOption(
    emoji: '📖',
    timeLabel: '30분',
    description: '꾸준히 한 단원씩',
    hoursPerWeek: 4,
  ),
  _StudyOption(
    emoji: '🎯',
    timeLabel: '1시간',
    description: '집중적으로 공부',
    hoursPerWeek: 7,
  ),
  _StudyOption(
    emoji: '🔥',
    timeLabel: '2시간 이상',
    description: '본격적인 학습',
    hoursPerWeek: 14,
  ),
];

// Weekend pacing presets — onboarding step 5. The number is sent as
// `weekendMultiplier` to /curricula/generate. Backend keeps the *weekly*
// total at hoursPerWeek and shifts mass between weekday/weekend by this
// ratio, so picking 2× doesn't secretly inflate study time.
class _WeekendOption {
  final String label;
  final String hint;
  final double multiplier;
  const _WeekendOption({required this.label, required this.hint, required this.multiplier});
}

const _weekendOptions = [
  _WeekendOption(label: '평일과 같음', hint: '매일 균등하게', multiplier: 1.0),
  _WeekendOption(label: '평일의 1.5배', hint: '주말에 조금 더 (기본)', multiplier: 1.5),
  _WeekendOption(label: '평일의 2배', hint: '주말에 몰아서', multiplier: 2.0),
];

class OnboardingHoursPage extends StatefulWidget {
  const OnboardingHoursPage({super.key});

  @override
  State<OnboardingHoursPage> createState() => _OnboardingHoursPageState();
}

class _OnboardingHoursPageState extends State<OnboardingHoursPage> {
  int? _selectedIndex;
  // Default to "평일의 1.5배" — matches the backend default so picking nothing
  // explicit yields the same plan as before this option existed.
  int _weekendIndex = 1;

  Map<String, dynamic> get _prevArgs =>
      (Get.arguments as Map<String, dynamic>?) ?? {};

  String get _certificateId => _prevArgs['certificateId'] as String? ?? '1';
  String? get _examDate => _prevArgs['examDate'] as String?;
  String? get _examSessionId => _prevArgs['examSessionId'] as String?;

  bool get _canContinue => _selectedIndex != null;

  int get _hoursPerWeek =>
      _selectedIndex != null ? _studyOptions[_selectedIndex!].hoursPerWeek : 7;

  double get _weekendMultiplier => _weekendOptions[_weekendIndex].multiplier;

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
        title: _buildProgressBar(colors, screenWidth, 0.75),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 24, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '하루에 얼마나\n공부할 수 있나요?',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      letterSpacing: -0.6,
                      color: colors.gray900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '공부 시간을 바탕으로 커리큘럼을 생성할게요.',
                    style: Typo.labelRegular(context, color: colors.gray300),
                  ),
                  const SizedBox(height: 28),
                  ...List.generate(_studyOptions.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudyOptionCard(
                        option: _studyOptions[i],
                        isSelected: _selectedIndex == i,
                        colors: colors,
                        onTap: () => setState(() => _selectedIndex = i),
                        context: context,
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                  Text(
                    '주말은 어떤가요?',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: colors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '주중 학습 시간을 평일/주말에 나눠서 분배할게요.',
                    style: Typo.labelRegular(context, color: colors.gray300),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_weekendOptions.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _WeekendChip(
                        option: _weekendOptions[i],
                        isSelected: _weekendIndex == i,
                        colors: colors,
                        onTap: () => setState(() => _weekendIndex = i),
                        context: context,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 32),
            child: CustomButton(
              text: '커리큘럼 생성하기',
              size: ButtonSize.large,
              theme: CustomButtonTheme.primary,
              disabled: !_canContinue,
              width: double.infinity,
              onPressed: !_canContinue
                  ? null
                  : () => Get.offAllNamed(
                        AppRoutes.onboardingGenerating,
                        arguments: {
                          'certificateId': _certificateId,
                          'examDate': _examDate,
                          'examSessionId': _examSessionId,
                          'hoursPerWeek': _hoursPerWeek,
                          'weekendMultiplier': _weekendMultiplier,
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

// ─────────────────────────────────────────────
// Weekend pacing chip (compact card variant)
// ─────────────────────────────────────────────
class _WeekendChip extends StatelessWidget {
  final _WeekendOption option;
  final bool isSelected;
  final ThemeColors colors;
  final VoidCallback onTap;
  final BuildContext context;

  const _WeekendChip({
    required this.option,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Semantics(
      button: true,
      label: '${option.label} - ${option.hint}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryLight : colors.gray0,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primaryNormal : colors.gray30,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isSelected ? colors.primaryNormal : colors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.hint,
                      style: Typo.labelRegular(
                        context,
                        color: isSelected ? colors.primaryDark : colors.gray300,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primaryNormal : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colors.primaryNormal : colors.gray100,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 12, color: colors.gray0)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Study Option Card
// ─────────────────────────────────────────────
class _StudyOptionCard extends StatelessWidget {
  final _StudyOption option;
  final bool isSelected;
  final ThemeColors colors;
  final VoidCallback onTap;
  final BuildContext context;

  const _StudyOptionCard({
    required this.option,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Semantics(
      button: true,
      label: '${option.timeLabel} - ${option.description}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryLight : colors.gray0,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.primaryNormal : colors.gray30,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primaryNormal.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Emoji icon in a small rounded square
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primaryNormal.withValues(alpha: 0.12)
                      : colors.gray20,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    option.emoji,
                    style: const TextStyle(
                      fontFamily: 'TossFace',
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Time label + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.timeLabel,
                      style: TextStyle(
                        fontFamily: 'SeoulAlrim',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.3,
                        color: isSelected
                            ? colors.primaryNormal
                            : colors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: Typo.labelRegular(
                        context,
                        color:
                            isSelected ? colors.primaryDark : colors.gray300,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color:
                      isSelected ? colors.primaryNormal : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? colors.primaryNormal
                        : colors.gray100,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 13, color: colors.gray0)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
