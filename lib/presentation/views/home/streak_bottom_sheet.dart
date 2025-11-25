import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/domain/models/home/streak_info.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class StreakBottomSheet extends StatelessWidget {
  final StreakInfo streakInfo;

  const StreakBottomSheet({super.key, required this.streakInfo});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final today = DateTime.now();
    final recentDays = List.of(streakInfo.recentDays)
      ..sort((a, b) => a.date.compareTo(b.date));

    final horizontalPadding = screenWidth * 0.046;
    final verticalPadding = screenWidth * 0.061;
    final indicatorWidth = screenWidth * 0.092;
    final indicatorHeight = screenWidth * 0.010;
    final indicatorTopPadding = screenWidth * 0.010;
    final iconSize = screenWidth * 0.107;
    final dayItemWidth = screenWidth * 0.114;
    final dayItemHeight = screenWidth * 0.14;
    final dayGap = screenWidth * 0.018;
    final contentGap = screenWidth * 0.031;
    final statWidth = screenWidth * 0.277;
    final statPadding = screenWidth * 0.031;

    return Container(
      decoration: BoxDecoration(
        color: colors.gray20,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: indicatorTopPadding),
            child: Container(
              width: indicatorWidth,
              height: indicatorHeight,
              decoration: BoxDecoration(
                color: colors.gray40,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              verticalPadding,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${streakInfo.currentStreak}',
                      style: Typo.displayStrong(context).copyWith(
                        color: colors.gray900,
                        fontSize: screenWidth * 0.122,
                        letterSpacing: -0.03 * screenWidth * 0.122,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.008),
                    Assets.icons.flashOn.svg(
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(
                        colors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: contentGap),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: dayGap,
                  runSpacing: dayGap,
                  children: recentDays
                      .map(
                        (day) => _buildDayItem(
                          context,
                          _weekdayLabel(day.date.weekday),
                          day.date.day.toString(),
                          day.isCompleted,
                          colors,
                          dayItemWidth,
                          dayItemHeight,
                          isToday: _isSameDay(day.date, today),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: contentGap),
                Container(
                  decoration: BoxDecoration(
                    color: colors.gray40,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.020),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(
                        context,
                        '${streakInfo.maxStreak}',
                        '최대 연속 학습일',
                        colors,
                        statWidth,
                        statPadding,
                        showBorder: true,
                      ),
                      _buildStatItem(
                        context,
                        '${streakInfo.completedCertificates}',
                        '완료한 자격증',
                        colors,
                        statWidth,
                        statPadding,
                        showBorder: true,
                      ),
                      _buildStatItem(
                        context,
                        '${streakInfo.completedLessons}',
                        '완료한 레슨',
                        colors,
                        statWidth,
                        statPadding,
                        showBorder: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(
    BuildContext context,
    String day,
    String date,
    bool isCompleted,
    ThemeColors colors,
    double width,
    double height, {
    bool isToday = false,
  }) {
    return Column(
      children: [
        Text(
          day,
          style: Typo.labelRegular(context).copyWith(
            color: colors.gray300,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        SizedBox(height: width * 0.089),
        Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(vertical: width * 0.044),
          decoration: BoxDecoration(
            color: isCompleted ? colors.primaryNormal : Colors.transparent,
            border: Border.all(
              color: isCompleted ? colors.primaryNormalActive : colors.gray70,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(46),
          ),
          child: Center(
            child: Text(
              date,
              style: Typo.bodyRegular(
                context,
              ).copyWith(color: isCompleted ? colors.gray0 : colors.gray90),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    ThemeColors colors,
    double width,
    double padding, {
    required bool showBorder,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding * 0.5,
      ),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(right: BorderSide(color: colors.gray300, width: 1))
            : null,
      ),
      width: width,
      child: Column(
        children: [
          Text(
            value,
            style: Typo.bodyStrong(context).copyWith(color: colors.gray900),
          ),
          Text(
            label,
            style: Typo.footnoteRegular(context).copyWith(color: colors.gray700),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final index = (weekday - 1) % labels.length;
    return labels[index < 0 ? index + labels.length : index];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
