import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
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

  Future<void> _onStartStudy() async {
    final currentMode = _viewModel.currentMode;
    final hd = _viewModel.homeData;
    final subjectName = (hd == null || hd.subjects.isEmpty)
        ? ''
        : (hd.subjects.firstWhere(
              (s) => !s.isCompleted,
              orElse: () => hd.subjects.first,
            ).name);
    
    Future<dynamic>? nav;
    switch (currentMode) {
      case StudyMode.concept:
        nav = Get.toNamed(AppRoutes.conceptStudy, arguments: {'subjectName': subjectName});
        break;
      case StudyMode.practice:
        nav = Get.toNamed(AppRoutes.practiceStudy, arguments: {'subjectName': subjectName});
        break;
      case StudyMode.review:
        nav = Get.toNamed(AppRoutes.mockExam, arguments: {'examName': subjectName, 'timeLimitMinutes': 150});
        break;
    }
    if (nav != null) {
      await nav;
      await _viewModel.refresh();
    }
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
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.049),
                      _buildStudyProgress(context, colors, homeData, screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.063),
                      _buildCurriculumSection(context, colors, homeData, screenWidth),
                      const Spacer(),
                    ],
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

  Widget _buildCurriculumSection(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth) {
    final horizontalPadding = screenWidth * 0.081;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.046,
          screenWidth * 0.081,
          screenWidth * 0.046,
          screenWidth * 0.031,
        ),
        decoration: BoxDecoration(
          color: colors.gray0,
          border: Border.all(color: colors.gray70, width: 1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            _buildCurriculumList(context, colors, homeData, screenWidth),
            SizedBox(height: screenWidth * 0.051),
            Semantics(
              button: true,
              identifier: 'home-start-cta',
              label: _viewModel.startButtonLabel,
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _viewModel.startButtonLabel,
                  size: ButtonSize.large,
                  theme: CustomButtonTheme.primary,
                  disabled: !_viewModel.canStartCurrentMode,
                  onPressed: () => _onStartStudy(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumList(BuildContext context, ThemeColors colors, dynamic homeData, double screenWidth) {
    int completedCount = 0;
    for (var subject in homeData.subjects) {
      if (subject.isCompleted) {
        completedCount++;
      } else {
        break;
      }
    }
    
    final subjectsToShow = homeData.subjects.skip(completedCount).take(2).toList();
    
    return Column(
      children: [
        for (int i = 0; i < subjectsToShow.length; i++) ...[
          if (i > 0) SizedBox(height: screenWidth * 0.031),
          Opacity(
            opacity: subjectsToShow[i].isCompleted ? 0.5 : 1.0,
            child: _buildCurriculumItem(
              context,
              subjectsToShow[i].name,
              subjectsToShow[i].isCompleted,
              colors,
              screenWidth,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurriculumItem(
    BuildContext context,
    String title,
    bool isCompleted,
    ThemeColors colors,
    double screenWidth,
  ) {
    final checkboxSize = screenWidth * 0.046;
    final iconSize = screenWidth * 0.041;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Typo.bodyRegular(context, color: colors.gray900),
        ),
        Container(
          width: checkboxSize,
          height: checkboxSize,
          decoration: BoxDecoration(
            color: isCompleted ? colors.primaryNormal : colors.gray40,
            borderRadius: BorderRadius.circular(isCompleted ? 99 : 12),
          ),
          child: isCompleted
              ? Center(
                    child: Assets.icons.check.svg(
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(colors.gray0, BlendMode.srcIn),
                    ),
                )
              : null,
        ),
      ],
    );
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