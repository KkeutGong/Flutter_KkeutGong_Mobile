import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/study/today_plan.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(null);
    _pageController = PageController();
    _viewModel.loadHomeData();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 24 * screenHeight / 852),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.049),
                        _buildStudyProgress(context, colors, homeData, screenWidth, screenHeight),
                        SizedBox(height: screenHeight * 0.045),
                        _buildTodayLauncher(context, colors, homeData, screenWidth),
                      ],
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

  Widget _buildStudyProgress(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth, double screenHeight) {
    final horizontalPadding = screenWidth * 0.188;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          _buildProgressBar(colors, homeData),
          SizedBox(height: screenHeight * 0.019),
          _buildStudyInfo(context, colors, homeData),
          SizedBox(height: screenHeight * 0.038),
          _buildStudyCardSlider(context, colors, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.019),
          _buildPageIndicators(colors, screenWidth),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeColors colors, dynamic homeData) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colors.gray90,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: homeData.progress,
          child: Container(
            decoration: BoxDecoration(
              color: colors.gray900,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyInfo(BuildContext context, ThemeColors colors, dynamic homeData) {
    return Column(
      children: [
        Text(
          homeData.currentCertificate.name,
          style: Typo.titleStrong(context, color: colors.gray900),
        ),
        const SizedBox(height: 5),
        Text(
          'Day ${homeData.currentDay}',
          style: Typo.headingStrong(context, color: colors.primaryNormal),
        ),
      ],
    );
  }

  Widget _buildStudyCardForMode(BuildContext context, ThemeColors colors, StudyMode mode, double screenWidth, double screenHeight) {
    final iconSize = screenWidth * 0.234;
    final horizontalPadding = screenWidth * 0.122;
    final verticalPadding = screenWidth * 0.061;
    final gap = screenWidth * 0.036;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: colors.gray0,
          border: Border.all(color: colors.gray300, width: 1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: _getIconForMode(mode, colors, iconSize),
            ),
            SizedBox(height: gap),
            Text(
              mode.displayName,
              style: Typo.titleStrong(context, color: colors.gray900),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getIconForMode(StudyMode mode, ThemeColors colors, double iconSize) {
    Widget icon;
    switch (mode) {
      case StudyMode.concept:
        icon = Assets.icons.draw.svg(
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
        break;
      case StudyMode.practice:
        icon = Assets.icons.article.svg(
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
        break;
      case StudyMode.review:
        icon = Assets.icons.menuBook.svg(
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
        break;
    }
    return icon;
  }

  Widget _buildStudyCardSlider(BuildContext context, ThemeColors colors, double screenWidth, double screenHeight) {
    final cardHeight = screenWidth * 0.48;

    return SizedBox(
      width: double.infinity,
      height: cardHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _viewModel.setCurrentMode(index);
        },
        itemCount: _viewModel.studyModes.length,
        itemBuilder: (context, index) {
          return _buildStudyCardForMode(context, colors, _viewModel.studyModes[index], screenWidth, screenHeight);
        },
      ),
    );
  }

  Widget _buildPageIndicators(ThemeColors colors, double screenWidth) {
    final indicatorSize = screenWidth * 0.023;
    final indicatorSpacing = screenWidth * 0.015;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _viewModel.studyModes.length,
        (index) => Padding(
          padding: EdgeInsets.only(left: index > 0 ? indicatorSpacing : 0),
          child: _buildPageIndicator(colors, index == _viewModel.currentModeIndex, indicatorSize),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(ThemeColors colors, bool isActive, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? colors.primaryNormal : colors.gray60,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Renders today's plan as a stack of per-subject task launcher cards.
  /// Each task gets its own card with its own progress and CTA so the user
  /// can pick what to start next instead of being forced into a fixed
  /// concept→practice→review carousel order. A mock-exam day pin sits at
  /// the top when today has a mockExam task. When everything is done, the
  /// soft-cap CTA "내일 카드에서 +N장 미리 풀기" appears so finishers can
  /// pull tomorrow forward without breaking the plan's pacing.
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
    final mockTasks = today.tasks.where((t) => t.type == TodayTaskType.mockExam).toList();
    final pendingTasks = today.tasks.where((t) => t.type != TodayTaskType.mockExam && !t.isComplete).toList();
    final doneTasks = today.tasks.where((t) => t.type != TodayTaskType.mockExam && t.isComplete).toList();

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