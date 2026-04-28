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

  // Calendar state
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  String get _certificateId =>
      (Get.arguments as Map<String, dynamic>?)?['certificateId'] as String? ??
      '1';

  bool get _canContinue => _examDate != null || _noFixedDate;

  String get _selectedDateLabel {
    if (_noFixedDate) return '정해진 일정 없음';
    if (_examDate == null) return '날짜를 선택해 주세요';
    return '${_examDate!.year}년 ${_examDate!.month}월 ${_examDate!.day}일';
  }

  String? get _dDayLabel {
    if (_examDate == null || _noFixedDate) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_examDate!.year, _examDate!.month, _examDate!.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  void _onDayTap(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) return;
    setState(() {
      _examDate = date;
      _noFixedDate = false;
    });
  }

  void _prevMonth() {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 24, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '언제까지 합격하고\n싶은지 알려주세요',
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
                    '시험 일정에 맞춰 커리큘럼을 생성할게요.',
                    style: Typo.labelRegular(context, color: colors.gray300),
                  ),
                  const SizedBox(height: 24),

                  // ── 선택 날짜 + D-day 표시 카드 ──
                  _SelectedDateBanner(
                    label: _selectedDateLabel,
                    dDay: _dDayLabel,
                    hasSelection: _examDate != null || _noFixedDate,
                    colors: colors,
                    context: context,
                  ),

                  const SizedBox(height: 16),

                  // ── 인라인 캘린더 ──
                  AnimatedOpacity(
                    opacity: _noFixedDate ? 0.35 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _noFixedDate,
                      child: _InlineCalendar(
                        displayMonth: _displayMonth,
                        selectedDate: _examDate,
                        onDayTap: _onDayTap,
                        onPrevMonth: _prevMonth,
                        onNextMonth: _nextMonth,
                        colors: colors,
                        context: context,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 정해진 일정 없음 ──
                  _NoScheduleToggle(
                    selected: _noFixedDate,
                    colors: colors,
                    context: context,
                    onTap: () => setState(() {
                      _noFixedDate = !_noFixedDate;
                      if (_noFixedDate) _examDate = null;
                    }),
                  ),

                  const SizedBox(height: 24),
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

// ─────────────────────────────────────────────
// Selected Date Banner
// ─────────────────────────────────────────────
class _SelectedDateBanner extends StatelessWidget {
  final String label;
  final String? dDay;
  final bool hasSelection;
  final ThemeColors colors;
  final BuildContext context;

  const _SelectedDateBanner({
    required this.label,
    required this.dDay,
    required this.hasSelection,
    required this.colors,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: hasSelection ? colors.primaryLight : colors.gray20,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSelection ? colors.primaryNormal : colors.gray30,
          width: hasSelection ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SeoulAlrim',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.4,
                color: hasSelection ? colors.primaryNormal : colors.gray100,
              ),
            ),
          ),
          if (dDay != null) ...[
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryNormal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dDay!,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: colors.gray0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Inline Calendar Widget
// ─────────────────────────────────────────────
class _InlineCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime? selectedDate;
  final void Function(DateTime) onDayTap;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ThemeColors colors;
  final BuildContext context;

  const _InlineCalendar({
    required this.displayMonth,
    required this.selectedDate,
    required this.onDayTap,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.colors,
    required this.context,
  });

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _korMonths = [
    '', '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월'
  ];

  List<DateTime?> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final startWeekday = firstDayOfMonth.weekday % 7; // 0=Sun
    final daysInMonth =
        DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);

    final cells = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(displayMonth.year, displayMonth.month, d));
    }
    // Pad to complete last row
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext ctx) {
    final cells = _buildCalendarDays();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.gray30, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
      child: Column(
        children: [
          // Month navigation header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPrevMonth,
                  icon: Icon(
                    Icons.chevron_left,
                    color: colors.gray400,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Text(
                  '${displayMonth.year}년 ${_korMonths[displayMonth.month]}',
                  style: Typo.bodyStrong(context, color: colors.gray900),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: Icon(
                    Icons.chevron_right,
                    color: colors.gray400,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: _weekdays.map((w) {
                final isSun = w == '일';
                final isSat = w == '토';
                return Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSun
                            ? const Color(0xffFF4035).withValues(alpha: 0.7)
                            : isSat
                                ? colors.primaryNormal.withValues(alpha: 0.7)
                                : colors.gray300,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Day grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: cells.length,
              itemBuilder: (_, index) {
                final date = cells[index];
                if (date == null) return const SizedBox.shrink();

                final isToday = date == today;
                final isSelected = selectedDate != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month &&
                    date.day == selectedDate!.day;
                final isPast = date.isBefore(today);
                final isSunday = date.weekday == DateTime.sunday;
                final isSaturday = date.weekday == DateTime.saturday;

                Color dayTextColor;
                if (isSelected) {
                  dayTextColor = colors.gray0;
                } else if (isPast) {
                  dayTextColor = colors.gray50;
                } else if (isSunday) {
                  dayTextColor = const Color(0xffFF4035).withValues(alpha: 0.85);
                } else if (isSaturday) {
                  dayTextColor = colors.primaryNormal.withValues(alpha: 0.85);
                } else {
                  dayTextColor = colors.gray900;
                }

                return GestureDetector(
                  onTap: isPast ? null : () => onDayTap(date),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primaryNormal
                            : isToday
                                ? colors.primaryLight
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: colors.primaryNormal, width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: dayTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// No Schedule Toggle
// ─────────────────────────────────────────────
class _NoScheduleToggle extends StatelessWidget {
  final bool selected;
  final ThemeColors colors;
  final BuildContext context;
  final VoidCallback onTap;

  const _NoScheduleToggle({
    required this.selected,
    required this.colors,
    required this.context,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primaryLight : colors.gray0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primaryNormal : colors.gray30,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? colors.primaryNormal : colors.gray0,
                border: Border.all(
                  color: selected ? colors.primaryNormal : colors.gray100,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: colors.gray0,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '정해진 일정 없음',
              style: Typo.bodyRegular(
                context,
                color: selected ? colors.primaryNormal : colors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
