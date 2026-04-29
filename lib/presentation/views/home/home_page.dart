import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/domain/models/study/today_plan.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/home/pass_meter.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/home_viewmodel.dart';
import 'package:kkeutgong_mobile/presentation/views/home/home_page_skeleton.dart';
import 'package:kkeutgong_mobile/presentation/views/home/streak_bottom_sheet.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(null);
    _viewModel.loadHomeData();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_viewModel.isLoading) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: buildHomeSkeletonLoading(context, colors, screenWidth, screenHeight),
      );
    }

    if (_viewModel.error != null) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: Center(child: Text('Error: ${_viewModel.error}')),
      );
    }

    final homeData = _viewModel.homeData;
    if (homeData == null) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: const Center(child: Text('No data')),
      );
    }

    return Scaffold(
      backgroundColor: colors.gray20,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, colors, homeData, screenWidth),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _viewModel.refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.only(bottom: 24 * screenHeight / 852),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.025),
                          _buildDailyHero(context, colors, homeData, screenWidth),
                          SizedBox(height: screenHeight * 0.018),
                          _buildCoachBanner(context, colors, screenWidth),
                          if (_viewModel.todayPlan?.adaptation?.changed == true) ...[
                            SizedBox(height: screenHeight * 0.012),
                            _buildAdaptationToast(context, colors, screenWidth),
                          ],
                          SizedBox(height: screenHeight * 0.022),
                          _buildTodayLauncher(context, colors, homeData, screenWidth),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_viewModel.isCertificateDropdownOpen)
            GestureDetector(
              onTap: _viewModel.closeCertificateDropdown,
              child: Container(
                color: Colors.black26,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.061,
                      top: screenHeight * 0.076,
                    ),
                    child: _buildCertificateDropdown(context, colors, homeData, screenWidth),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Hero card at the top of the home tab. Shows cert + D-day on the left
  /// and the always-on pass-likelihood gauge on the right. Tap on the gauge
  /// opens a bottom sheet that explains how the number was computed (so the
  /// user trusts the AI signal).
  Widget _buildDailyHero(
    BuildContext context,
    ThemeColors colors,
    dynamic homeData,
    double screenWidth,
  ) {
    final hp = screenWidth * 0.06;
    final today = _viewModel.todayPlan;
    final dDay = today?.dDay;
    final certName = (homeData.currentCertificate.name as String?) ?? '';
    final passValue = today?.passLikelihood ?? 0;
    final reason = today?.passLikelihoodReason ?? '';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryNormal.withValues(alpha: 0.95),
              colors.primaryNormal.withValues(alpha: 0.78),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.primaryNormal.withValues(alpha: 0.18),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.gray0.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      dDay != null ? 'D-$dDay' : '시험일 미정',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.gray0,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    certName.isNotEmpty ? certName : '자격증',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.gray0,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '오늘 따라가면 합격까지 갑니다.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.gray0.withValues(alpha: 0.92),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showPassLikelihoodSheet(context, colors, passValue, reason),
              child: PassMeter(value: passValue, size: 96),
            ),
          ],
        ),
      ),
    );
  }

  void _showPassLikelihoodSheet(
    BuildContext context,
    ThemeColors colors,
    int value,
    String reason,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.gray0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '합격 가능성 $value%',
              style: TextStyle(
                fontFamily: 'SeoulAlrim',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.gray900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason.isNotEmpty
                  ? reason
                  : '아직 학습 데이터가 없어요. 오늘 첫 학습이 첫 점수가 됩니다.',
              style: Typo.bodyRegular(context, color: colors.gray700)
                  .copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.gray20,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '계산식 = 연습 정답률 50% + 진도 30% + 모의고사 20%. 학습량이 적은 동안엔 보수적으로 표시됩니다.',
                style: Typo.labelRegular(context, color: colors.gray500)
                    .copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Always-on coach banner. Renders even when Qwen is unreachable — the
  /// backend produces a deterministic fallback so this view never empty.
  Widget _buildCoachBanner(
    BuildContext context,
    ThemeColors colors,
    double screenWidth,
  ) {
    final hp = screenWidth * 0.06;
    final coach = _viewModel.todayPlan?.coachMessage;
    if (coach == null || coach.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.gray0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.gray70),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1, right: 10),
              child: Text('🧠', style: TextStyle(fontSize: 18, fontFamily: 'TossFace')),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI 코치',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryNormal,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (coach.isFallback) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.gray20,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '기본 가이드',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.gray500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coach.text,
                    style: Typo.bodyRegular(context, color: colors.gray900)
                        .copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders only when /study/today reports a recent recompute. The toast
  /// names the top 1-2 subject deltas so the user feels the AI adapted.
  Widget _buildAdaptationToast(
    BuildContext context,
    ThemeColors colors,
    double screenWidth,
  ) {
    final hp = screenWidth * 0.06;
    final adapt = _viewModel.todayPlan?.adaptation;
    if (adapt == null || !adapt.changed) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.primaryNormal.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: colors.primaryNormal, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI가 plan을 조정했어요 — ${adapt.summary}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryNormal,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth) {
    final horizontalPadding = screenWidth * 0.061;
    final verticalPadding = screenWidth * 0.031;

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCertificateButton(context, colors, screenWidth),
              _buildAppBarActions(context, colors, homeData, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateButton(BuildContext context, ThemeColors colors, double screenWidth) {
    final iconSize = screenWidth * 0.081;
    final arrowSize = screenWidth * 0.071;
    final homeData = _viewModel.homeData;

    return Semantics(
      button: true,
      identifier: 'home-cert-dropdown',
      label: '자격증 변경',
      child: GestureDetector(
      onTap: _viewModel.toggleCertificateDropdown,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.013,
          vertical: screenWidth * 0.010,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colors.gray300, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: _getIconForCertificate(
                homeData?.currentCertificate.icon ?? 'memory',
                colors,
              ),
            ),
            SizedBox(
              width: arrowSize,
              height: arrowSize,
              child: (_viewModel.isCertificateDropdownOpen
                      ? Assets.icons.keyboardArrowUp
                      : Assets.icons.keyboardArrowDown)
                  .svg(
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAppBarActions(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth) {
    final iconSize = screenWidth * 0.081;

    return Row(
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: Assets.icons.notificationsUnread.svg(
            colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
          ),
        ),
        SizedBox(width: screenWidth * 0.031),
        _buildStreakButton(context, colors, homeData, screenWidth),
      ],
    );
  }

  Widget _buildStreakButton(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth) {
    final iconSize = screenWidth * 0.061;

    return Semantics(
      button: true,
      identifier: 'home-streak',
      label: '스트릭 상세',
      child: GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => StreakBottomSheet(
            streakInfo: homeData.streakInfo,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.028,
          vertical: screenWidth * 0.010,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colors.gray300, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Text(
              '${homeData.streakDays}',
              style: Typo.titleStrong(context, color: colors.gray900),
            ),
            SizedBox(width: screenWidth * 0.010),
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Stack(
                children: [
                  Assets.icons.flashOnFill.svg(
                    width: iconSize,
                    height: iconSize,
                    colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.0025),
                    child: Assets.icons.flashOnFill.svg(
                      width: iconSize * 0.875,
                      height: iconSize * 0.875,
                      colorFilter: const ColorFilter.mode(Color(0xFFF5C905), BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTodayLauncher(
    BuildContext context,
    ThemeColors colors,
    dynamic homeData,
    double screenWidth,
  ) {
    final hp = screenWidth * 0.081;
    final today = _viewModel.todayPlan;
    final subjects = (homeData.subjects as List).cast<dynamic>();
    final subjectNameById = <String, String>{
      for (final s in subjects) (s.id as String): (s.name as String),
    };

    if (today == null || today.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hp, vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.gray70),
          ),
          child: Column(
            children: [
              Icon(Icons.event_available, color: colors.gray100, size: 32),
              const SizedBox(height: 8),
              Text(
                '오늘 예정된 학습이 없어요',
                style: Typo.bodyRegular(context, color: colors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '커리큘럼 탭에서 일정을 확인해 보세요.',
                style: Typo.labelRegular(context, color: colors.gray400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Sort: mockExam first (pinned banner), then incomplete tasks, then
    // already-done tasks so the user's current attention sits up top.
    // Render order driven by the AI-adaptive `orderedTasks` from the
    // backend, not the raw curriculum order, so the user sees the weakest
    // subject first today (and a different one tomorrow).
    final ordered = today.orderedTasks.isNotEmpty ? today.orderedTasks : today.tasks;
    final mockTasks = ordered.where((t) => t.type == TodayTaskType.mockExam).toList();
    final pendingTasks = ordered.where((t) => t.type != TodayTaskType.mockExam && !t.isComplete).toList();
    final doneTasks = ordered.where((t) => t.type != TodayTaskType.mockExam && t.isComplete).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mockTasks.isNotEmpty)
            ...mockTasks.map((t) => _buildMockExamCallout(context, colors, homeData, t)),
          if (mockTasks.isNotEmpty) const SizedBox(height: 12),
          ...pendingTasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLauncherCard(context, colors, t, subjectNameById, locked: false),
              )),
          if (doneTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
              child: Text(
                '오늘 완료한 학습',
                style: Typo.labelRegular(context, color: colors.gray400),
              ),
            ),
            ...doneTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildLauncherCard(context, colors, t, subjectNameById, locked: true),
                )),
          ],
          if (today.isAllDone && today.softCapAvailable > 0)
            _buildSoftCapCTA(context, colors, homeData, today.softCapAvailable),
          if (today.isAllDone && today.softCapAvailable == 0)
            _buildAllDoneSuccess(context, colors),
        ],
      ),
    );
  }

  Widget _buildMockExamCallout(
    BuildContext context,
    ThemeColors colors,
    dynamic homeData,
    TodayTask task,
  ) {
    final minutes = (homeData.currentCertificate.mockExamMinutes as int?) ?? 90;
    final certName = homeData.currentCertificate.name as String;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.gray900, colors.gray700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, color: colors.gray0, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.isComplete ? '오늘 모의고사 완료!' : '오늘은 모의고사 보는 날',
                  style: TextStyle(
                    fontFamily: 'SeoulAlrim',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.gray0,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$minutes분 · ${task.completed}/${task.planned}회',
                  style: Typo.labelRegular(context, color: colors.gray70),
                ),
              ],
            ),
          ),
          if (!task.isComplete)
            CustomButton(
              text: '시작',
              size: ButtonSize.medium,
              theme: CustomButtonTheme.primary,
              onPressed: () async {
                await Get.toNamed(AppRoutes.mockExam, arguments: {
                  'examName': '$certName 모의고사',
                  'timeLimitMinutes': minutes,
                });
                await _viewModel.refresh();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLauncherCard(
    BuildContext context,
    ThemeColors colors,
    TodayTask task,
    Map<String, String> subjectNameById,
    {required bool locked}
  ) {
    final subjectName = task.subjectId != null
        ? (subjectNameById[task.subjectId!] ?? task.subjectId!)
        : '';
    final modeLabel = _todayTypeLabel(task.type);
    final emoji = _todayTypeEmoji(task.type);
    final progress = task.planned > 0 ? task.completed / task.planned : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: locked ? colors.gray20 : colors.gray0,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: locked ? colors.gray30 : colors.gray70),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: locked ? colors.gray30 : colors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (subjectName.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          subjectName,
                          overflow: TextOverflow.ellipsis,
                          style: Typo.bodyRegular(context,
                              color: locked ? colors.gray400 : colors.gray700),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '· $modeLabel',
                      style: Typo.labelRegular(context, color: colors.gray400),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  locked
                      ? '${task.planned}장 완료'
                      : '${task.completed}/${task.planned}',
                  style: TextStyle(
                    fontFamily: 'SeoulAlrim',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: locked ? colors.gray400 : colors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: colors.gray30,
                      valueColor: AlwaysStoppedAnimation(colors.primaryNormal),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (locked)
            Icon(Icons.check_circle, color: colors.primaryNormal, size: 22)
          else
            CustomButton(
              text: task.completed > 0 ? '이어하기' : '시작',
              size: ButtonSize.medium,
              theme: CustomButtonTheme.primary,
              onPressed: () => _launchTask(task, subjectName),
            ),
        ],
      ),
    );
  }

  Widget _buildSoftCapCTA(
    BuildContext context,
    ThemeColors colors,
    dynamic homeData,
    int softCapAvailable,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primaryNormal),
      ),
      child: Column(
        children: [
          Text(
            '오늘 학습 끝!',
            style: TextStyle(
              fontFamily: 'SeoulAlrim',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.primaryNormal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '여유 있으면 내일 분량 +$softCapAvailable장을 미리 풀 수 있어요.',
            style: Typo.labelRegular(context, color: colors.gray700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: '+$softCapAvailable장 미리 풀기',
              size: ButtonSize.medium,
              theme: CustomButtonTheme.primary,
              onPressed: () async {
                final subjects = (homeData.subjects as List).cast<dynamic>();
                final firstUnlocked = subjects.isNotEmpty ? subjects.first : null;
                if (firstUnlocked == null) return;
                await Get.toNamed(AppRoutes.conceptStudy, arguments: {
                  'subjectName': firstUnlocked.name as String,
                  'extra': softCapAvailable,
                });
                await _viewModel.refresh();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDoneSuccess(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, size: 36, color: colors.primaryNormal),
          const SizedBox(height: 8),
          Text(
            '오늘 분량 끝! 잘했어요',
            style: TextStyle(
              fontFamily: 'SeoulAlrim',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.gray900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '내일 다시 만나요.',
            style: Typo.labelRegular(context, color: colors.gray500),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTask(TodayTask task, String subjectName) async {
    Future<dynamic>? nav;
    switch (task.type) {
      case TodayTaskType.concept:
        nav = Get.toNamed(AppRoutes.conceptStudy,
            arguments: {'subjectName': subjectName});
        break;
      case TodayTaskType.practice:
        nav = Get.toNamed(AppRoutes.practiceStudy,
            arguments: {'subjectName': subjectName});
        break;
      case TodayTaskType.review:
        // Review re-uses the favorites/wrongs screen for now. The dedicated
        // wrong-answer queue lives at AppRoutes.reviewWrongs (added as part
        // of the same feature) and is reached from the post-mock CTA.
        nav = Get.toNamed(AppRoutes.review,
            arguments: {'subjectName': subjectName});
        break;
      case TodayTaskType.mockExam:
      case TodayTaskType.unknown:
        return;
    }
    if (nav != null) {
      await nav;
      await _viewModel.refresh();
    }
  }

  String _todayTypeLabel(TodayTaskType type) {
    switch (type) {
      case TodayTaskType.concept:
        return '개념정리';
      case TodayTaskType.practice:
        return '기출문제';
      case TodayTaskType.review:
        return '복습';
      case TodayTaskType.mockExam:
        return '모의고사';
      case TodayTaskType.unknown:
        return '학습';
    }
  }

  String _todayTypeEmoji(TodayTaskType type) {
    switch (type) {
      case TodayTaskType.concept:
        return '📘';
      case TodayTaskType.practice:
        return '✍️';
      case TodayTaskType.review:
        return '🔁';
      case TodayTaskType.mockExam:
        return '📝';
      case TodayTaskType.unknown:
        return '📚';
    }
  }

  Widget _buildCertificateDropdown(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth) {
    final iconSize = screenWidth * 0.081;
    final arrowSize = screenWidth * 0.071;
    final dropdownItemSize = screenWidth * 0.076;
    final currentCertId = homeData.currentCertificate.id;
    final otherCertificates = homeData.allCertificates.where((cert) => cert.id != currentCertId).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.gray20,
            border: Border(
              top: BorderSide(color: colors.gray300, width: 1),
              left: BorderSide(color: colors.gray300, width: 1),
              right: BorderSide(color: colors.gray300, width: 1),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.036,
            vertical: screenWidth * 0.020,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: _getIconForCertificate(homeData.currentCertificate.icon, colors),
              ),
              SizedBox(
                width: arrowSize,
                height: arrowSize,
                child: Assets.icons.keyboardArrowUp.svg(
                  colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: screenWidth * 0.224,
          decoration: BoxDecoration(
            color: colors.gray20,
            border: Border(
              left: BorderSide(color: colors.gray300, width: 1),
              right: BorderSide(color: colors.gray300, width: 1),
              bottom: BorderSide(color: colors.gray300, width: 1),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.036,
            screenWidth * 0.008,
            screenWidth * 0.036,
            screenWidth * 0.020,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < otherCertificates.length; i++) ...[
                if (i > 0) SizedBox(height: screenWidth * 0.025),
                GestureDetector(
                  onTap: () => _viewModel.selectCertificate(otherCertificates[i]),
                  child: SizedBox(
                    width: dropdownItemSize,
                    height: dropdownItemSize,
                    child: _getIconForCertificate(otherCertificates[i].icon, colors),
                  ),
                ),
              ],
              if (otherCertificates.isNotEmpty) SizedBox(height: screenWidth * 0.025),
              Semantics(
                button: true,
                identifier: 'home-add-certificate',
                label: '자격증 추가',
                child: GestureDetector(
                  onTap: () {
                    _viewModel.closeCertificateDropdown();
                    Get.toNamed(AppRoutes.addCertificate);
                  },
                  child: SizedBox(
                    width: dropdownItemSize,
                    height: dropdownItemSize,
                    child: Icon(
                      Icons.add_circle_outline,
                      size: dropdownItemSize * 0.85,
                      color: colors.gray900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getIconForCertificate(String iconName, ThemeColors colors) {
    switch (iconName) {
      case 'desktop_mac':
        return Assets.icons.desktopMac.svg(
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      case 'menu_book':
        return Assets.icons.menuBook.svg(
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      default:
        return Assets.icons.memory.svg(
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
    }
  }
}