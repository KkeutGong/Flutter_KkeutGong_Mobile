import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/curriculum_viewmodel.dart';
import 'package:kkeutgong_mobile/presentation/views/curriculum/curriculum_page_skeleton.dart';
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

  @override
  void initState() {
    super.initState();
    _viewModel = CurriculumViewModel(null);
    _viewModel.addListener(_onChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
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
    final dDayLabel = dDay <= 0 ? 'D-DAY' : 'D-$dDay';

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
                    Text(
                      dDayLabel,
                      style: Typo.labelStrong(
                        context,
                        color: colors.primaryNormal,
                      ),
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
          CustomButton(
            text: '모의고사 보기',
            size: ButtonSize.medium,
            theme: CustomButtonTheme.primary,
            disabled: !isExamReady,
            onPressed: isExamReady ? () => _navigateToMockExam(data.currentCertificate.name) : null,
          ),
        ],
      ),
    );
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
    final subjects = _viewModel.subjects;
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
    final locked = _viewModel.isUnitLocked(subject, mode);
    final enabled = _viewModel.unitButtonEnabled(subject, mode);
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
          _buildUnitButton(colors, label, enabled, completed, locked, subject, mode),
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
          AppRoutes.practiceStudy,
          arguments: {'subjectName': subject.name},
        );
        break;
    }
    await _viewModel.refresh();
  }

  Future<void> _navigateToMockExam(String certificateName) async {
    await Get.toNamed(
      AppRoutes.mockExam,
      arguments: {
        'examName': '$certificateName 모의고사',
        'timeLimitMinutes': 150,
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

  Widget _buildUnitButton(
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
    } else if (locked) {
      background = colors.gray900;
      textColor = colors.gray0;
    } else {
      background = colors.gray900;
      textColor = colors.gray0;
    }

    return CustomButton(
      text: label,
      size: ButtonSize.small,
      theme: CustomButtonTheme.grayscale,
      disabled: !enabled,
      backgroundColor: background,
      textColor: textColor,
      onPressed: enabled ? () => _navigateToStudyPage(subject, mode) : null,
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
