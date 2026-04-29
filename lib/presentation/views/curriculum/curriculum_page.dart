import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/domain/models/curriculum/curriculum_plan.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/curriculum_viewmodel.dart';
import 'package:kkeutgong_mobile/presentation/views/curriculum/curriculum_page_skeleton.dart';
import 'package:kkeutgong_mobile/presentation/views/curriculum/exam_date_change_sheet.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  late final CurriculumViewModel _viewModel;
  final ScrollController _dayTabsController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = CurriculumViewModel(null);
    _viewModel.addListener(_onChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    _dayTabsController.dispose();
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(0.85, 1.4);
    final isTablet = width >= 600;
    final horizontalPadding = isTablet ? 48.0 : 30.0 * scale;

    if (_viewModel.isLoading) {
      return Scaffold(
        backgroundColor: colors.primaryNormal,
        body: buildCurriculumSkeletonLoading(context, colors, scale, horizontalPadding),
      );
    }

    if (_viewModel.error != null) {
      return Scaffold(
        backgroundColor: colors.primaryNormal,
        body: Center(child: Text(_viewModel.error!)),
      );
    }

    final data = _viewModel.homeData;
    if (data == null) {
      return Scaffold(
        backgroundColor: colors.primaryNormal,
        body: const Center(child: Text('데이터를 불러오지 못했습니다.')),
      );
    }

    final sectionWidgets = _buildSections(context, colors);

    return Scaffold(
      backgroundColor: colors.primaryNormal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCertificateList(context, colors, data, scale, horizontalPadding),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.gray0,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummarySection(context, colors, data, scale, isTablet, horizontalPadding),
                      _buildDayTabs(context, colors, scale, horizontalPadding),
                      _buildTodayPlanSection(context, colors, scale, horizontalPadding),
                      if (sectionWidgets.isNotEmpty) ...[
                        const SizedBox(height: 60),
                        ...sectionWidgets,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateList(
    BuildContext context,
    ThemeColors colors,
    HomeData data,
    double scale,
    double horizontalPadding,
  ) {
    return SizedBox(
      height: 134 * scale,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          24 * scale,
          horizontalPadding,
          18 * scale,
        ),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final certificate = data.allCertificates[index];
          final isActive = certificate.id == data.currentCertificate.id;
          return _buildCertificateCard(context, colors, certificate, isActive, scale);
        },
        separatorBuilder: (_, __) => SizedBox(width: 30 * scale),
        itemCount: data.allCertificates.length,
      ),
    );
  }

  Widget _buildCertificateCard(
    BuildContext context,
    ThemeColors colors,
    Certificate certificate,
    bool isActive,
    double scale,
  ) {
    return GestureDetector(
      onTap: () => _viewModel.selectCertificate(certificate.id),
      child: Opacity(
        opacity: isActive ? 1 : 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.gray0,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.gray70),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28 * scale,
                    vertical: 12 * scale,
                  ),
                  child: _buildCertificateIcon(certificate.icon, colors, scale),
                ),
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              certificate.name,
              style: Typo.labelRegular(context, color: colors.gray0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    ThemeColors colors,
    HomeData data,
    double scale,
    bool isTablet,
    double horizontalPadding,
  ) {
    final dDay = _viewModel.examDDay;
    final progressValue = _viewModel.progress.clamp(0.0, 1.0);
    final percentage = (progressValue * 100).round();
    final isExamReady = _viewModel.isExamReady;
    // No curriculum yet → don't pretend "today is exam day". Show a neutral
    // placeholder until the user finishes onboarding.
    final dDayLabel = !_viewModel.hasExamDate
        ? '시험일 미정'
        : dDay <= 0
            ? 'D-DAY'
            : 'D-$dDay';

    return Container(
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.fromLTRB(
        isTablet ? horizontalPadding : 24 * scale,
        15 * scale,
        isTablet ? horizontalPadding : 24 * scale,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.currentCertificate.name,
                      style: Typo.titleStrong(context, color: colors.gray900),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          dDayLabel,
                          style: Typo.labelStrong(
                            context,
                            color: colors.primaryNormal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Semantics(
                          button: true,
                          identifier: 'curriculum-change-exam-date',
                          label: '시험일 변경',
                          child: GestureDetector(
                            onTap: () => _onChangeExamDate(data.currentCertificate.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.gray70,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.gray500,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8 * scale),
                Row(
                  children: [
                    SizedBox(
                      width: 151 * scale,
                      child: _buildOverallProgressBar(colors, progressValue),
                    ),
                    SizedBox(width: 3 * scale),
                    Text(
                      '$percentage%',
                      style: Typo.labelRegular(context, color: colors.gray900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            identifier: 'curriculum-mock-exam',
            label: '모의고사 보기',
            child: CustomButton(
              text: '모의고사 보기',
              size: ButtonSize.medium,
              theme: CustomButtonTheme.primary,
              disabled: !isExamReady,
              onPressed: () {
                if (isExamReady) {
                  _navigateToMockExam(data.currentCertificate.name);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 과목을 완료한 후 모의고사를 볼 수 있어요'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal day tabs that scope the rest of the curriculum tab to a
  /// single day in the user's plan. Auto-scrolls to today on first build so
  /// the default view matches the user's mental model ("내 오늘의 학습").
  Widget _buildDayTabs(
    BuildContext context,
    ThemeColors colors,
    double scale,
    double horizontalPadding,
  ) {
    final plan = _viewModel.myCurriculum?.plan;
    if (plan == null || plan.days.isEmpty) return const SizedBox.shrink();
    final selectedIdx = _viewModel.selectedDayIndex;
    final todayIdx = _viewModel.todayDayIndex;

    // Auto-scroll the strip so the selected day is visible. Each pill is
    // ~64px wide; nudge by a few items so today doesn't sit at the very edge.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dayTabsController.hasClients) return;
      final target =
          (selectedIdx * 72.0 - 80).clamp(0.0, _dayTabsController.position.maxScrollExtent);
      _dayTabsController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 16 * scale, 0, 4 * scale),
      child: SizedBox(
        height: 56 * scale,
        child: ListView.separated(
          controller: _dayTabsController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          physics: const BouncingScrollPhysics(),
          itemCount: plan.days.length,
          separatorBuilder: (_, __) => SizedBox(width: 8 * scale),
          itemBuilder: (context, index) {
            final day = plan.days[index];
            final isSelected = index == selectedIdx;
            final isToday = index == todayIdx;
            final isSprint = day.phase == CurriculumDayPhase.sprint;
            final bg = isSelected
                ? (isSprint ? colors.gray900 : colors.primaryNormal)
                : colors.gray0;
            final fg = isSelected ? colors.gray0 : colors.gray700;
            final border = isSelected
                ? (isSprint ? colors.gray900 : colors.primaryNormal)
                : colors.gray70;

            return GestureDetector(
              onTap: () => _viewModel.selectDay(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: border, width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Day ${day.day}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      isToday ? '오늘' : '${day.date.month}/${day.date.day}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: fg.withValues(alpha: isSelected ? 1 : 0.65),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodayPlanSection(
    BuildContext context,
    ThemeColors colors,
    double scale,
    double horizontalPadding,
  ) {
    final counts = _viewModel.selectedDayTaskCounts;
    final hasAnyTask = counts.conceptCount > 0 ||
        counts.practiceCount > 0 ||
        counts.reviewCount > 0 ||
        counts.mockExamCount > 0;

    // "콘텐츠 준비중" — backend reports an empty content guard. Show a
    // friendly placeholder so the user isn't staring at an empty screen.
    if (_viewModel.planEmptyContent) {
      return _buildContentPlaceholder(context, colors, scale, horizontalPadding);
    }
    // No plan or past the planned window. Summary section above shows D-day
    // already, so we just hide.
    if (!hasAnyTask) {
      return const SizedBox.shrink();
    }

    final selectedDay = _viewModel.selectedDay;
    final viewedDate = selectedDay?.date ?? DateTime.now();
    final dateLabel = '${viewedDate.month}월 ${viewedDate.day}일';
    final isToday = _viewModel.selectedDayIsToday;
    // Today shows real progress; future/past days show 0 (no live progress
    // signal for non-today plans).
    final progress = isToday ? _viewModel.todayProgress : 0.0;
    final percent = (progress * 100).round();
    final isSprint = (selectedDay?.phase == CurriculumDayPhase.sprint);
    final overload = _viewModel.planOverload;
    final coachingMessage = _viewModel.coachingMessage;
    final completed = isToday ? _viewModel.todayCompleted : 0;
    final planned =
        isToday ? _viewModel.todayPlanned : (selectedDay?.tasks.fold<int>(0, (sum, t) => sum + t.count) ?? 0);

    final accentColor = isSprint ? colors.gray900 : colors.primaryNormal;
    final accentLight = isSprint ? colors.gray70 : colors.primaryLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16 * scale, horizontalPadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (coachingMessage != null) ...[
            _buildCoachingBanner(context, colors, coachingMessage, scale),
            SizedBox(height: 10 * scale),
          ],
          if (overload) ...[
            _buildOverloadBanner(context, colors, scale),
            SizedBox(height: 10 * scale),
          ],
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 14 * scale),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isSprint
                            ? '마무리 스프린트'
                            : (isToday ? '오늘의 학습' : 'Day ${selectedDay?.day ?? 1}'),
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.gray0,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _todayTasksLabel(
                          counts.conceptCount,
                          counts.practiceCount,
                          counts.reviewCount,
                          counts.mockExamCount,
                        ),
                        style: Typo.bodyRegular(context, color: colors.gray900),
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: Typo.labelRegular(context, color: colors.gray500),
                    ),
                  ],
                ),
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: colors.gray70,
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      planned > 0 ? '$completed / $planned · $percent%' : '$percent%',
                      style: Typo.labelStrong(context, color: accentColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Korean coaching message produced by the LLM (Qwen). Surfaced above
  /// today's plan so the user understands *why* this plan looks the way it
  /// does ("이번 주는 데이터베이스 비중을 늘렸어요 — 모의고사 정답률이 60%였거든요").
  Widget _buildCoachingBanner(
    BuildContext context,
    ThemeColors colors,
    String message,
    double scale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.gray70),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: Text(
              '🧠',
              style: TextStyle(fontSize: 16, fontFamily: 'TossFace'),
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: Typo.bodyRegular(context, color: colors.gray900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverloadBanner(
    BuildContext context,
    ThemeColors colors,
    double scale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB266)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('⚠️', style: TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              '시험까지 시간이 빠듯해요. 학습 시간을 늘리거나 시험일을 조정해 보세요.',
              style: Typo.labelRegular(context, color: const Color(0xFF8C5A00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPlaceholder(
    BuildContext context,
    ThemeColors colors,
    double scale,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16 * scale, horizontalPadding, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 18 * scale),
        decoration: BoxDecoration(
          color: colors.gray0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.gray70),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '콘텐츠 준비중이에요',
              style: Typo.titleStrong(context, color: colors.gray900),
            ),
            SizedBox(height: 6 * scale),
            Text(
              '이 자격증의 학습 자료를 만들고 있어요. 준비가 끝나는 대로 알려드릴게요.',
              style: Typo.bodyRegular(context, color: colors.gray500),
            ),
          ],
        ),
      ),
    );
  }

  String _todayTasksLabel(int concept, int practice, int review, int mockExam) {
    final parts = <String>[];
    if (mockExam > 0) parts.add('모의고사 $mockExam회');
    if (concept > 0) parts.add('개념 $concept장');
    if (practice > 0) parts.add('문제 $practice개');
    if (review > 0) parts.add('복습 $review개');
    return parts.join(' · ');
  }

  Widget _buildOverallProgressBar(ThemeColors colors, double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: colors.gray50,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clampedProgress,
          child: Container(
            decoration: BoxDecoration(
              color: clampedProgress == 0 ? Colors.transparent : colors.gray900,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, ThemeColors colors) {
    // Subjects in scope of the currently selected day. Future-day subjects
    // appear with disabled buttons (locked until that day arrives) so the
    // user can preview the roadmap without launching a study session out
    // of order.
    final subjects = _viewModel.selectedDaySubjects;
    final items = <Widget>[];
    for (int i = 0; i < subjects.length; i++) {
      if (i > 0) {
        items.add(const SizedBox(height: 60));
      }
      final isPreviousSubjectIncomplete = i > 0 && !subjects[i - 1].isCompleted;
      items.add(_buildSubjectSection(context, colors, subjects[i], isPreviousSubjectIncomplete));
    }
    return items;
  }

  Widget _buildSubjectSection(
    BuildContext context,
    ThemeColors colors,
    Subject subject,
    bool isPreviousSubjectIncomplete,
  ) {
    final opacity = subject.isCompleted ? 0.5 : (isPreviousSubjectIncomplete ? 0.5 : 1.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width >= 600 ? 56 : 32 * (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.4),
      ),
      child: Opacity(
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(context, colors, subject.name),
            SizedBox(height: 20 * (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.4)),
            ..._buildUnitList(context, colors, subject),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeColors colors,
    String title,
  ) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: colors.gray300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: Typo.bodyRegular(context, color: colors.gray300),
          ),
        ),
        Expanded(child: Container(height: 1, color: colors.gray300)),
      ],
    );
  }

  List<Widget> _buildUnitList(
    BuildContext context,
    ThemeColors colors,
    Subject subject,
  ) {
    final modes = _viewModel.studyModes;
    final widgets = <Widget>[];
    for (int i = 0; i < modes.length; i++) {
      widgets.add(_buildUnitCard(context, colors, subject, modes[i], i));
      if (i < modes.length - 1) {
        widgets.add(_buildConnector(colors));
      }
    }
    return widgets;
  }

  Widget _buildUnitCard(
    BuildContext context,
    ThemeColors colors,
    Subject subject,
    StudyMode mode,
    int index,
  ) {
    final progress = _viewModel.progressPercentage(subject, mode);
    final label = _viewModel.unitButtonLabel(subject, mode);
    // Lock everything when previewing a non-today day — past days lose
    // meaning to start fresh, and future days haven't unlocked yet.
    final isViewingToday = _viewModel.selectedDayIsToday;
    final locked = !isViewingToday || _viewModel.isUnitLocked(subject, mode);
    final enabled = isViewingToday && _viewModel.unitButtonEnabled(subject, mode);
    final completed = progress >= 1;
    final textColor = subject.isCompleted ? colors.gray600 : colors.gray900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gray70),
        boxShadow: [
          BoxShadow(
            color: colors.gray70,
            offset: const Offset(0, 2),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${index + 1}.',
                  style: Typo.titleStrong(context, color: textColor),
                ),
                SizedBox(width: 32 * (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.4)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.displayName,
                        style: Typo.headingRegular(context, color: textColor),
                      ),
                      SizedBox(height: 8 * (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.4)),
                      _buildUnitProgressBar(colors, progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 32 * (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.4)),
          Semantics(
            button: true,
            identifier: 'curriculum-${subject.id}-${mode.name}',
            label: label,
            child: _buildUnitButton(context, colors, label, enabled, completed, locked, subject, mode),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToStudyPage(Subject subject, StudyMode mode) async {
    switch (mode) {
      case StudyMode.concept:
        await Get.toNamed(
          AppRoutes.conceptStudy,
          arguments: {'subjectName': subject.name},
        );
        break;
      case StudyMode.practice:
        await Get.toNamed(
          AppRoutes.practiceStudy,
          arguments: {'subjectName': subject.name},
        );
        break;
      case StudyMode.review:
        await Get.toNamed(
          AppRoutes.review,
          arguments: {'subjectName': subject.name},
        );
        break;
    }
    await _viewModel.refresh();
  }

  Future<void> _onChangeExamDate(String certificateId) async {
    final ok = await ExamDateChangeSheet.show(
      context: context,
      certificateId: certificateId,
      currentCurriculum: _viewModel.myCurriculum,
    );
    if (ok == true) {
      // Refresh draws the new D-day, plan, and today's-progress numbers in
      // one pass instead of relying on a stale cache.
      await _viewModel.refresh();
    }
  }

  Future<void> _navigateToMockExam(String certificateName) async {
    final minutes =
        _viewModel.homeData?.currentCertificate.mockExamMinutes ?? 90;
    await Get.toNamed(
      AppRoutes.mockExam,
      arguments: {
        'examName': '$certificateName 모의고사',
        'timeLimitMinutes': minutes,
      },
    );
    await _viewModel.refresh();
  }

  Widget _buildUnitProgressBar(ThemeColors colors, double progress) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: progress > 0 ? colors.primaryNormal : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }

  String _lockedMessage(StudyMode mode) {
    switch (mode) {
      case StudyMode.practice:
        return '개념정리를 먼저 완료해 주세요';
      case StudyMode.review:
        return '기출문제를 먼저 완료해 주세요';
      case StudyMode.concept:
        return '이전 단계를 먼저 완료해 주세요';
    }
  }

  Widget _buildUnitButton(
    BuildContext context,
    ThemeColors colors,
    String label,
    bool enabled,
    bool completed,
    bool locked,
    Subject subject,
    StudyMode mode,
  ) {
    Color background;
    Color textColor;

    if (completed) {
      background = colors.greenLight;
      textColor = colors.gray900;
    } else {
      background = colors.gray900;
      textColor = colors.gray0;
    }

    void onTap() {
      if (enabled) {
        _navigateToStudyPage(subject, mode);
      } else if (locked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_lockedMessage(mode))),
        );
      }
    }

    return CustomButton(
      text: label,
      size: ButtonSize.small,
      theme: CustomButtonTheme.grayscale,
      disabled: !enabled,
      backgroundColor: background,
      textColor: textColor,
      onPressed: completed ? null : onTap,
    );
  }

  Widget _buildConnector(ThemeColors colors) {
    return Center(
      child: Container(
        width: 3,
        height: 23,
        decoration: BoxDecoration(
          color: colors.gray70,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildCertificateIcon(String iconName, ThemeColors colors, double scale) {
    switch (iconName) {
      case 'desktop_mac':
        return Assets.icons.desktopMac.svg(
          width: 36 * scale,
          height: 36 * scale,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      case 'menu_book':
        return Assets.icons.menuBook.svg(
          width: 36 * scale,
          height: 36 * scale,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      case 'memory':
        return Assets.icons.memory.svg(
          width: 36 * scale,
          height: 36 * scale,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      default:
        return Assets.icons.memory.svg(
          width: 36 * scale,
          height: 36 * scale,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
    }
  }
}
