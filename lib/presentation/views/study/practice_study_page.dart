import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/study/practice_study_viewmodel.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/empty_state.dart';
import 'package:kkeutgong_mobile/presentation/widgets/study/answer_feedback_sheet.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';

class _ResponsiveHelper {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final bool isSmallScreen;
  late final bool isMediumScreen;
  late final double scaleFactor;

  _ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isSmallScreen = screenWidth < 360;
    isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    scaleFactor = (screenWidth / 375).clamp(0.85, 1.2);
  }

  double get horizontalPadding => isSmallScreen ? 20 : (isMediumScreen ? 26 : 31);
  double get iconSize => (24 * scaleFactor).clamp(20.0, 28.0);
  double get smallIconSize => (16 * scaleFactor).clamp(14.0, 20.0);
  double get numberBadgeSize => (24 * scaleFactor).clamp(20.0, 28.0);
  double get choicePaddingH => isSmallScreen ? 14 : (isMediumScreen ? 17 : 20);
  double get choicePaddingV => isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
  double get buttonPaddingH => isSmallScreen ? 24 : (isMediumScreen ? 28 : 33);
  double get explanationPaddingH => isSmallScreen ? 24 : (isMediumScreen ? 30 : 35);
  double get explanationPaddingV => isSmallScreen ? 28 : (isMediumScreen ? 34 : 40);
}

class PracticeStudyPage extends StatefulWidget {
  final String subjectName;
  const PracticeStudyPage({super.key, required this.subjectName});
  @override
  State<PracticeStudyPage> createState() => _PracticeStudyPageState();
}

class _PracticeStudyPageState extends State<PracticeStudyPage> {
  late final PracticeStudyViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = PracticeStudyViewModel(subjectName: widget.subjectName);
    _viewModel.addListener(_onChanged);
    _viewModel.loadQuestions();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final responsive = _ResponsiveHelper(context);
    if (_viewModel.isLoading && !_viewModel.isInitialized) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final q = _viewModel.currentQuestion;
    if (q == null) {
      // questions list is empty (content not uploaded yet) → friendly empty
      // state. The 'index OOB' case is an internal bug we'd rather surface as
      // the same screen than crash mid-study.
      return Scaffold(
        backgroundColor: colors.gray20,
        appBar: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          title: Text(
            widget.subjectName,
            style: Typo.titleStrong(context, color: colors.gray900),
          ),
        ),
        body: const EmptyState(
          icon: Icons.quiz_outlined,
          message: '아직 이 과목 문제가 준비되지 않았어요.\n곧 기출문제를 채워서 알려드릴게요!',
        ),
      );
    }
    final hasAnswered = _viewModel.hasAnswered;
    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _buildAppBar(context, colors, responsive),
      body: SafeArea(
          child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              await _viewModel.saveProgress();
              HomeRepository().invalidateCache();
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 24 * responsive.scaleFactor, responsive.horizontalPadding, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(context, colors, q, responsive),
                          SizedBox(height: 60 * responsive.scaleFactor),
                          _buildChoices(context, colors, q, responsive),
                          SizedBox(height: 50 * responsive.scaleFactor),
                          if (hasAnswered)
                            _buildExplanation(context, colors, q, responsive),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(colors, responsive),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: colors.gray0,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Semantics(
            identifier: 'practice-back',
            label: '뒤로 가기',
            button: true,
            child: GestureDetector(
            onTap: () async {
              await _viewModel.saveProgress();
              HomeRepository().invalidateCache();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.all(15 * responsive.scaleFactor),
              child: Assets.icons.arrowBackIos.svg(
                width: responsive.iconSize,
                height: responsive.iconSize,
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
            ),
          ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: 12 * responsive.scaleFactor,
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _viewModel.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primaryNormal,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15 * responsive.scaleFactor),
              Text(
                _viewModel.progressText,
                style: Typo.bodyRegular(context, color: colors.gray900),
              ),
              SizedBox(width: 15 * responsive.scaleFactor),
            ],
          ),
          titleSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, ThemeColors colors, Question q, _ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.sourceLabel != null && q.sourceLabel!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: colors.primaryNormal.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              q.sourceLabel!,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.primaryNormal,
                letterSpacing: -0.2,
              ),
            ),
          ),
          SizedBox(height: 10 * responsive.scaleFactor),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${q.number}.',
              style: Typo.titleStrong(context, color: colors.gray900),
            ),
            SizedBox(width: 10 * responsive.scaleFactor),
            Expanded(
              child: Text(
                q.text,
                style: Typo.headingStrong(context, color: colors.gray900),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoices(BuildContext context, ThemeColors colors, Question q, _ResponsiveHelper responsive) {
    final hasAnswered = _viewModel.hasAnswered;
    return Column(
      children: q.choices
          .map<Widget>(
            (choice) => Padding(
              padding: EdgeInsets.only(bottom: 10 * responsive.scaleFactor),
              child: _buildChoiceItem(context, colors, q, choice, hasAnswered, responsive),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChoiceItem(
    BuildContext context,
    ThemeColors colors,
    Question q,
    Choice choice,
    bool hasAnswered,
    _ResponsiveHelper responsive,
  ) {
    final isSelected = q.selectedAnswer == choice.number;
    final isCorrect = choice.isCorrect;
    final answeredCorrect = hasAnswered && isSelected && isCorrect;
    final showCorrectBadge = hasAnswered && !answeredCorrect && isCorrect;
    Color bg = colors.gray0;
    Color border = colors.gray900;
    Color numBg = colors.gray30;
    if (hasAnswered) {
      if (answeredCorrect) {
        bg = colors.greenLightHover;
        border = colors.greenNormalHover;
        numBg = colors.greenLightActive;
      } else if (isCorrect) {
        bg = colors.gray0;
        border = colors.greenNormalHover;
        numBg = colors.greenLightActive;
      } else if (isSelected) {
        bg = colors.redLightHover;
        border = colors.redNormalHover;
        numBg = colors.redLightActive;
      }
    }
    return Semantics(
      identifier: 'practice-choice-${choice.number}',
      label: '${choice.number}번 보기 선택',
      button: true,
      child: GestureDetector(
      onTap: hasAnswered
          ? null
          : () async {
              _viewModel.selectAnswer(choice.number);
              // After locking the answer, immediately pop the AI feedback
              // sheet so the user gets a tailored explanation right at the
              // moment of confusion. Same pattern across practice/mock/review.
              await AnswerFeedbackSheet.show(
                context,
                questionId: q.id,
                selectedAnswer: choice.number,
                localExplanation: q.explanation,
              );
            },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: responsive.choicePaddingH, vertical: responsive.choicePaddingV),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
          border: Border.all(color: border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: responsive.numberBadgeSize,
                  height: responsive.numberBadgeSize,
                  decoration: BoxDecoration(
                    color: numBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${choice.number}',
                    style: Typo.bodyRegular(context, color: colors.gray900),
                  ),
                ),
                SizedBox(width: 8 * responsive.scaleFactor),
                Expanded(
                  child: Text(
                    choice.text,
                    style: (hasAnswered && isCorrect) || isSelected
                        ? Typo.bodyStrong(context, color: colors.gray900)
                        : Typo.bodyRegular(context, color: colors.gray900),
                  ),
                ),
              ],
            ),
            if (showCorrectBadge)
              Positioned(
                top: -30 * responsive.scaleFactor,
                right: -30 * responsive.scaleFactor,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * responsive.scaleFactor,
                    vertical: 2 * responsive.scaleFactor,
                  ),
                  decoration: BoxDecoration(
                    color: colors.greenLightHover,
                    borderRadius: BorderRadius.circular(6 * responsive.scaleFactor),
                    border: Border.all(color: colors.greenNormalHover),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Assets.icons.check.svg(
                        width: responsive.smallIconSize,
                        height: responsive.smallIconSize,
                        colorFilter: ColorFilter.mode(
                          colors.gray900,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 4 * responsive.scaleFactor),
                      Text(
                        '정답',
                        style: Typo.footnoteRegular(
                          context,
                          color: colors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildExplanation(
    BuildContext context,
    ThemeColors colors,
    Question q,
    _ResponsiveHelper responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('해설', style: Typo.bodyStrong(context, color: colors.gray900)),
        SizedBox(height: 4 * responsive.scaleFactor),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
            border: Border.all(color: colors.gray70),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.explanationPaddingH,
                  vertical: responsive.explanationPaddingV,
                ),
                child: Text(
                  q.explanation,
                  style: Typo.bodyRegular(context, color: colors.gray900),
                ),
              ),
              if (!_viewModel.showExplanation)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              if (!_viewModel.showExplanation)
                Positioned.fill(
                  child: Center(
                    child: Semantics(
                      identifier: 'practice-explanation-toggle',
                      label: '해설 보기',
                      button: true,
                      child: GestureDetector(
                      onTap: _viewModel.toggleExplanation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * responsive.scaleFactor,
                          vertical: 6 * responsive.scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryNormal,
                          borderRadius: BorderRadius.circular(6 * responsive.scaleFactor),
                          border: Border.all(color: colors.primaryNormalHover),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Assets.icons.visibility.svg(
                              width: responsive.smallIconSize,
                              height: responsive.smallIconSize,
                              colorFilter: ColorFilter.mode(
                                colors.gray0,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: 4 * responsive.scaleFactor),
                            Text(
                              '해설보기',
                              style: Typo.footnoteRegular(
                                context,
                                color: colors.gray0,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildBottomButton(ThemeColors colors, _ResponsiveHelper responsive) {
    final enabled = _viewModel.hasAnswered;
    final last = !_viewModel.hasNext;
    return Container(
      padding: EdgeInsets.fromLTRB(responsive.buttonPaddingH, 12 * responsive.scaleFactor, responsive.buttonPaddingH, 20 * responsive.scaleFactor),
      child: SizedBox(
        width: double.infinity,
        child: Semantics(
          identifier: 'practice-next',
          label: '다음 문제',
          button: true,
          child: GestureDetector(
          onTap: enabled
              ? () {
                  if (last) {
                    Navigator.pop(context);
                  } else {
                    _viewModel.goToNext();
                  }
                }
              : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: responsive.choicePaddingH, vertical: responsive.choicePaddingV),
              decoration: BoxDecoration(
                color: colors.gray900,
                borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
              ),
              alignment: Alignment.center,
              child: Text(
                '다음으로',
                style: Typo.bodyRegular(context, color: colors.gray0),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
