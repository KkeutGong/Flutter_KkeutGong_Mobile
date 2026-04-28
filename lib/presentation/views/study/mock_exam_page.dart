import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/domain/models/study/exam_result.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/study/mock_exam_viewmodel.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

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

  double get horizontalPadding => isSmallScreen ? 20 : (isMediumScreen ? 25 : 30);
  double get iconSize => (24 * scaleFactor).clamp(20.0, 28.0);
  double get smallIconSize => (16 * scaleFactor).clamp(14.0, 20.0);
  double get mediumIconSize => (20 * scaleFactor).clamp(18.0, 24.0);
  double get largeIconSize => (28 * scaleFactor).clamp(24.0, 32.0);
  double get numberBadgeSize => (24 * scaleFactor).clamp(20.0, 28.0);
  double get smallNumberBadgeSize => (22 * scaleFactor).clamp(18.0, 26.0);
  double get questionCircleSize => (50 * scaleFactor).clamp(42.0, 58.0);
  double get choicePaddingH => isSmallScreen ? 14 : (isMediumScreen ? 17 : 20);
  double get choicePaddingV => isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
  double get buttonPaddingH => isSmallScreen ? 24 : (isMediumScreen ? 29 : 34);
  double get modalPadding => isSmallScreen ? 18 : (isMediumScreen ? 21 : 24);
  double get explanationPaddingH => isSmallScreen ? 24 : (isMediumScreen ? 30 : 35);
  double get explanationPaddingV => isSmallScreen ? 28 : (isMediumScreen ? 34 : 40);
}

class MockExamPage extends StatefulWidget {
  final String examName;
  final int timeLimitMinutes;

  const MockExamPage({
    super.key,
    required this.examName,
    this.timeLimitMinutes = 150,
  });

  @override
  State<MockExamPage> createState() => _MockExamPageState();
}

class _MockExamPageState extends State<MockExamPage> {
  late final MockExamViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MockExamViewModel(
      examName: widget.examName,
      timeLimitMinutes: widget.timeLimitMinutes,
    );
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadQuestions();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToQuestion(int index) {
    _viewModel.goToQuestion(index);
    Navigator.of(context).pop();
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _SubmitConfirmationDialog(
        unansweredCount: _viewModel.unansweredCount,
        onSubmit: () {
          _viewModel.submitExam();
        },
      ),
    );
  }

  void _showAllQuestions() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _AllQuestionsModal(
        questions: _viewModel.questions,
        currentIndex: _viewModel.currentIndex,
        onSelect: _goToQuestion,
        isReviewMode: _viewModel.state == ExamState.submitted,
      ),
    );
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

    if (_viewModel.state == ExamState.ready) {
      return _StartScreen(
        examName: widget.examName,
        timeLimitMinutes: widget.timeLimitMinutes,
        questions: _viewModel.questions,
        currentIndex: _viewModel.currentIndex,
        onStart: _viewModel.startExam,
        onClose: () => Navigator.of(context).pop(),
        responsive: responsive,
      );
    }

    if (_viewModel.state == ExamState.submitted && _viewModel.result != null) {
      return _ResultPage(
        result: _viewModel.result!,
        questions: _viewModel.questions,
        currentIndex: _viewModel.currentIndex,
        onViewAllQuestions: _showAllQuestions,
        onPrevious: _viewModel.goToPrevious,
        onNext: _viewModel.goToNext,
        onComplete: () => Navigator.of(context).pop(),
        responsive: responsive,
      );
    }

    if (_viewModel.state == ExamState.submitFailed) {
      // Don't fall back to fake client-side scoring — make the user retry so
      // they always see the same pass/fail the server records.
      return Scaffold(
        backgroundColor: colors.gray20,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 56, color: colors.gray500),
                  const SizedBox(height: 16),
                  Text(
                    '결과를 저장하지 못했어요',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '네트워크 상태를 확인하고 다시 시도해 주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: colors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryNormal,
                        foregroundColor: colors.gray0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _viewModel.retrySubmit,
                      child: const Text('다시 제출'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '나가기',
                      style: TextStyle(color: colors.gray500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _ExamPage(
      questions: _viewModel.questions,
      currentIndex: _viewModel.currentIndex,
      remainingSeconds: _viewModel.remainingSeconds,
      onSelectAnswer: _viewModel.selectAnswer,
      onNext: _viewModel.goToNext,
      onPrevious: _viewModel.goToPrevious,
      onSubmit: _showSubmitConfirmation,
      onClose: () => Navigator.of(context).pop(),
      allAnswered: _viewModel.allAnswered,
      responsive: responsive,
    );
  }
}

class _StartScreen extends StatelessWidget {
  final String examName;
  final int timeLimitMinutes;
  final List<Question> questions;
  final int currentIndex;
  final VoidCallback onStart;
  final VoidCallback onClose;
  final _ResponsiveHelper responsive;

  const _StartScreen({
    required this.examName,
    required this.timeLimitMinutes,
    required this.questions,
    required this.currentIndex,
    required this.onStart,
    required this.onClose,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final question = questions.isNotEmpty ? questions[currentIndex] : null;

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _buildAppBar(context, colors),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTimerBar(context, colors),
                if (question != null)
                  Expanded(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(responsive.horizontalPadding - 3, 24 * responsive.scaleFactor, responsive.horizontalPadding - 3, 100 * responsive.scaleFactor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestionTitle(context, colors, question),
                            SizedBox(height: 60 * responsive.scaleFactor),
                            _buildChoices(context, colors, question),
                          ],
                        ),
                      ),
                    ),
                  ),
                _buildBottomButton(context, colors, false),
              ],
            ),
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 50 * responsive.scaleFactor),
                padding: EdgeInsets.all(responsive.modalPadding),
                decoration: BoxDecoration(
                  color: colors.gray0,
                  borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                  border: Border.all(color: colors.gray70),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안내사항',
                      style: Typo.headingStrong(context, color: colors.gray900),
                    ),
                    SizedBox(height: 24 * responsive.scaleFactor),
                    Column(
                      children: [
                        Text(
                          '- 모의고사모드는 실제 시험장과 비슷한 환경을 제공해 드려요.',
                          style: Typo.bodyRegular(
                            context,
                            color: colors.gray300,
                          ),
                        ),
                        Text(
                          '- 제한 시간이 있으며 시험을 제출하면 시험 결과와 다시 보기를 진행 할 수 있어요',
                          style: Typo.bodyRegular(
                            context,
                            color: colors.gray300,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * responsive.scaleFactor),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        '제한 시간: $timeLimitMinutes분',
                        style: Typo.bodyStrong(context, color: colors.gray900),
                      ),
                    ),
                    SizedBox(height: 24 * responsive.scaleFactor),
                    Center(
                      child: Semantics(
                        identifier: 'mock-exam-start',
                        label: '모의고사 시작',
                        button: true,
                        child: CustomButton(
                        text: '시험 응시하기',
                        size: ButtonSize.medium,
                        theme: CustomButtonTheme.grayscale,
                        onPressed: onStart,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context, ThemeColors colors) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: colors.gray0,
          border: Border(bottom: BorderSide(color: colors.gray70)),
        ),
        child: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Semantics(
            identifier: 'mock-exam-back-ready',
            label: '뒤로 가기',
            button: true,
            child: GestureDetector(
            onTap: onClose,
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
                    widthFactor: questions.isNotEmpty
                        ? (currentIndex / questions.length)
                        : 0,
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
                '$currentIndex/${questions.length}',
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

  Widget _buildTimerBar(BuildContext context, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15 * responsive.scaleFactor, vertical: 15 * responsive.scaleFactor),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '남은시간: $timeLimitMinutes분',
            style: Typo.bodyRegular(context, color: colors.redNormal),
          ),
          CustomButton(
            text: '제출',
            size: ButtonSize.small,
            theme: CustomButtonTheme.grayscale,
            disabled: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTitle(
    BuildContext context,
    ThemeColors colors,
    Question q,
  ) {
    return Row(
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
    );
  }

  Widget _buildChoices(BuildContext context, ThemeColors colors, Question q) {
    return Column(
      children: q.choices.map((choice) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10 * responsive.scaleFactor),
          child: GestureDetector(
            onTap: null,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: responsive.choicePaddingH, vertical: responsive.choicePaddingV),
              decoration: BoxDecoration(
                color: colors.gray0,
                borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                border: Border.all(color: colors.gray900),
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
                          color: colors.gray30,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${choice.number}',
                          style: Typo.bodyRegular(
                            context,
                            color: colors.gray900,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * responsive.scaleFactor),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: Typo.bodyRegular(
                            context,
                            color: colors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ThemeColors colors,
    bool hasAnswer,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: responsive.buttonPaddingH),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: '이전으로',
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: true,
            ),
          ),
          SizedBox(width: 12 * responsive.scaleFactor),
          Expanded(
            child: CustomButton(
              text: '다음으로',
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: !hasAnswer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamPage extends StatelessWidget {
  final List<Question> questions;
  final int currentIndex;
  final int remainingSeconds;
  final Function(int) onSelectAnswer;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;
  final VoidCallback onClose;
  final bool allAnswered;
  final _ResponsiveHelper responsive;

  const _ExamPage({
    required this.questions,
    required this.currentIndex,
    required this.remainingSeconds,
    required this.onSelectAnswer,
    required this.onNext,
    required this.onPrevious,
    required this.onSubmit,
    required this.onClose,
    required this.allAnswered,
    required this.responsive,
  });

  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
  }

  int get _answeredCount =>
      questions.where((q) => q.selectedAnswer != null).length;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final question = questions[currentIndex];
    final hasAnswer = question.selectedAnswer != null;

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _buildAppBar(context, colors),
      body: SafeArea(
        child: Column(
          children: [
            _buildTimerBar(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 24 * responsive.scaleFactor, responsive.horizontalPadding, 20 * responsive.scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionTitle(context, colors, question),
                    SizedBox(height: 60 * responsive.scaleFactor),
                    _buildChoices(context, colors, question),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context, colors, hasAnswer),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context, ThemeColors colors) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: colors.gray0,
          border: Border(bottom: BorderSide(color: colors.gray70)),
        ),
        child: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Semantics(
            identifier: 'mock-exam-back-progress',
            label: '뒤로 가기',
            button: true,
            child: GestureDetector(
            onTap: onClose,
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
                    widthFactor: questions.isNotEmpty
                        ? (_answeredCount / questions.length)
                        : 0,
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
                '$_answeredCount/${questions.length}',
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

  Widget _buildTimerBar(BuildContext context, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15 * responsive.scaleFactor, vertical: 15 * responsive.scaleFactor),
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
      child: Row(
        mainAxisAlignment: allAnswered
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '남은시간: $_formattedTime',
            style: Typo.bodyRegular(context, color: colors.redNormal),
          ),
          if (!allAnswered) ...[
            Semantics(
              identifier: 'mock-exam-submit',
              label: '제출하기',
              button: true,
              child: CustomButton(
              text: '제출',
              size: ButtonSize.small,
              theme: CustomButtonTheme.grayscale,
              onPressed: onSubmit,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionTitle(
    BuildContext context,
    ThemeColors colors,
    Question q,
  ) {
    return Row(
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
    );
  }

  Widget _buildChoices(
    BuildContext context,
    ThemeColors colors,
    Question question,
  ) {
    return Column(
      children: question.choices.map((choice) {
        final isSelected = question.selectedAnswer == choice.number;
        return Padding(
          padding: EdgeInsets.only(bottom: 10 * responsive.scaleFactor),
          child: Semantics(
            identifier: 'mock-exam-choice-${choice.number}',
            label: '${choice.number}번 보기 선택',
            button: true,
            child: GestureDetector(
            onTap: () => onSelectAnswer(choice.number),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: responsive.choicePaddingH, vertical: responsive.choicePaddingV),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryLightHover : colors.gray0,
                borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                border: Border.all(
                  color: isSelected ? colors.primaryNormal : colors.gray900,
                ),
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
                          color: isSelected
                              ? colors.primaryLightActive
                              : colors.gray30,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${choice.number}',
                          style: Typo.bodyRegular(
                            context,
                            color: colors.gray900,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * responsive.scaleFactor),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: isSelected
                              ? Typo.bodyStrong(context, color: colors.gray900)
                              : Typo.bodyRegular(
                                  context,
                                  color: colors.gray900,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ThemeColors colors,
    bool hasAnswer,
  ) {
    final isFirstQuestion = currentIndex == 0;
    final isLastQuestion = currentIndex == questions.length - 1;
    final buttonText = (allAnswered && isLastQuestion) ? '제출하기' : '다음으로';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: responsive.buttonPaddingH),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              identifier: 'mock-exam-previous',
              label: '이전 문제',
              button: true,
              child: CustomButton(
              text: '이전으로',
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: isFirstQuestion,
              onPressed: onPrevious,
              ),
            ),
          ),
          SizedBox(width: 12 * responsive.scaleFactor),
          Expanded(
            child: Semantics(
              identifier: 'mock-exam-next-or-submit',
              label: (allAnswered && isLastQuestion) ? '제출하기' : '다음 문제',
              button: true,
              child: CustomButton(
              text: buttonText,
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: !hasAnswer,
              onPressed: (allAnswered && isLastQuestion) ? onSubmit : onNext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitConfirmationDialog extends StatelessWidget {
  final int unansweredCount;
  final VoidCallback onSubmit;

  const _SubmitConfirmationDialog({
    required this.unansweredCount,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final responsive = _ResponsiveHelper(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(responsive.modalPadding),
        decoration: BoxDecoration(
          color: colors.gray0,
          borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '제출하시겠어요?',
              style: Typo.headingStrong(context, color: colors.gray900),
            ),
            SizedBox(height: 10 * responsive.scaleFactor),
            Text(
              '풀이 화면으로 다시 돌아올 수 없어요',
              style: Typo.labelRegular(context, color: colors.gray300),
            ),
            SizedBox(height: 24 * responsive.scaleFactor),
            Row(
              children: [
                Text(
                  '풀지 않은 문제',
                  style: Typo.labelRegular(context, color: colors.gray900),
                ),
                const Spacer(),
                Text(
                  '$unansweredCount문제',
                  style: Typo.labelRegular(context, color: colors.redNormal),
                ),
              ],
            ),
            SizedBox(height: 24 * responsive.scaleFactor),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    identifier: 'mock-exam-cancel',
                    label: '취소',
                    button: true,
                    child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16 * responsive.scaleFactor),
                      decoration: BoxDecoration(
                        color: colors.redLightHover,
                        border: Border.all(color: colors.redNormalHover),
                        borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '취소',
                        style: Typo.bodyRegular(context, color: colors.gray900),
                      ),
                    ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * responsive.scaleFactor),
                Expanded(
                  child: Semantics(
                    identifier: 'mock-exam-confirm',
                    label: '제출하기',
                    button: true,
                    child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onSubmit();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16 * responsive.scaleFactor),
                      decoration: BoxDecoration(
                        color: colors.gray900,
                        borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '제출하기',
                        style: Typo.bodyRegular(context, color: colors.gray0),
                      ),
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllQuestionsModal extends StatelessWidget {
  final List<Question> questions;
  final int currentIndex;
  final Function(int) onSelect;
  final bool isReviewMode;

  const _AllQuestionsModal({
    required this.questions,
    required this.currentIndex,
    required this.onSelect,
    this.isReviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final responsive = _ResponsiveHelper(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 25 * responsive.scaleFactor),
          padding: EdgeInsets.all(responsive.modalPadding),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
            border: Border.all(color: colors.gray300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '문제 전체보기',
                          style: Typo.headingStrong(context, color: colors.gray900),
                        ),
                        SizedBox(height: 10 * responsive.scaleFactor),
                        Text(
                          '번호를 누르면 해당 번호로 이동해요',
                          style: Typo.footnoteRegular(context, color: colors.gray600),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    identifier: 'mock-exam-dialog-close',
                    label: '닫기',
                    button: true,
                    child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Assets.icons.close.svg(
                      width: responsive.largeIconSize,
                      height: responsive.largeIconSize,
                      colorFilter: ColorFilter.mode(
                        colors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 44 * responsive.scaleFactor),
              _buildQuestionGrid(context, colors, responsive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionGrid(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    final rows = <Widget>[];
    for (int i = 0; i < questions.length; i += 5) {
      final rowItems = <Widget>[];
      for (int j = i; j < i + 5 && j < questions.length; j++) {
        final question = questions[j];
        
        Color backgroundColor = colors.gray0;
        Color borderColor = colors.gray900;
        
        if (isReviewMode && question.isCorrect != null) {
          if (question.isCorrect!) {
            backgroundColor = colors.greenLightHover;
            borderColor = colors.greenNormalHover;
          } else {
            backgroundColor = colors.redLightHover;
            borderColor = colors.redNormalHover;
          }
        }

        rowItems.add(
          Semantics(
            identifier: 'mock-exam-jump-$j',
            label: '${j + 1}번 문제로 이동',
            button: true,
            child: GestureDetector(
            onTap: () => onSelect(j),
            child: Container(
              width: responsive.questionCircleSize,
              height: responsive.questionCircleSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: Text(
                '${j + 1}',
                style: Typo.bodyRegular(context, color: colors.gray900),
              ),
            ),
          ),
          ),
        );
      }

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowItems,
        ),
      );
    }

    return Column(
      children: rows
          .map((row) => Padding(
                padding: EdgeInsets.only(bottom: 26 * responsive.scaleFactor),
                child: row,
              ))
          .toList(),
    );
  }
}

class _ResultPage extends StatefulWidget {
  final ExamResult result;
  final List<Question> questions;
  final int currentIndex;
  final VoidCallback onViewAllQuestions;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;
  final _ResponsiveHelper responsive;

  const _ResultPage({
    required this.result,
    required this.questions,
    required this.currentIndex,
    required this.onViewAllQuestions,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
    required this.responsive,
  });

  @override
  State<_ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<_ResultPage> {
  bool _showExplanation = false;

  String get _formattedTime {
    final minutes = widget.result.elapsedTime.inMinutes;
    return '$minutes 분';
  }

  @override
  void didUpdateWidget(covariant _ResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _showExplanation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final responsive = widget.responsive;

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding + 3,
                  vertical: 24 * responsive.scaleFactor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection(context, colors, responsive),
                    SizedBox(height: 24 * responsive.scaleFactor),
                    _buildSubjectScoresSection(context, colors, responsive),
                    SizedBox(height: 24 * responsive.scaleFactor),
                    _buildQuestionReviewSection(context, colors, responsive),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context, colors, responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학습 개요',
          style: Typo.headingStrong(context, color: colors.gray900),
        ),
        SizedBox(height: 12 * responsive.scaleFactor),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16 * responsive.scaleFactor, vertical: 32 * responsive.scaleFactor),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
            border: Border.all(color: colors.gray300),
          ),
          child: Column(
            children: [
              _buildSummaryRow(context, colors, '총 문제 수', '${widget.result.totalQuestions} 문제'),
              SizedBox(height: 10 * responsive.scaleFactor),
              _buildSummaryRow(context, colors, '맞은 문제 수', '${widget.result.correctCount} 문제'),
              SizedBox(height: 10 * responsive.scaleFactor),
              _buildSummaryRow(context, colors, '걸린 시간', _formattedTime),
              SizedBox(height: 16 * responsive.scaleFactor),
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 16 * responsive.scaleFactor),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.gray300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '합격 여부',
                      style: Typo.headingStrong(context, color: colors.gray900),
                    ),
                    Text(
                      widget.result.isPassed ? '합격' : '불합격',
                      style: Typo.headingRegular(
                        context,
                        color: widget.result.isPassed ? colors.greenNormal : colors.redNormal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    ThemeColors colors,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Typo.bodyStrong(context, color: colors.gray900)),
        Text(value, style: Typo.bodyRegular(context, color: colors.redNormal)),
      ],
    );
  }

  Widget _buildSubjectScoresSection(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    final scores = widget.result.subjectScores.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '과목별 맞은 문제 수',
          style: Typo.headingStrong(context, color: colors.gray900),
        ),
        SizedBox(height: 12 * responsive.scaleFactor),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(32 * responsive.scaleFactor),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
            border: Border.all(color: colors.gray300),
          ),
          child: Column(
            children: [
              for (int i = 0; i < scores.length; i++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      scores[i].name,
                      style: Typo.bodyRegular(context, color: colors.gray900),
                    ),
                    SizedBox(
                      width: 47 * responsive.scaleFactor,
                      child: Text(
                        '${scores[i].correctCount} / ${scores[i].totalQuestions}',
                        style: Typo.bodyRegular(context, color: colors.gray600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                if (i < scores.length - 1) ...[
                  SizedBox(height: 16 * responsive.scaleFactor),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: colors.gray300,
                  ),
                  SizedBox(height: 16 * responsive.scaleFactor),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewSection(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    if (widget.questions.isEmpty ||
        widget.currentIndex >= widget.questions.length) {
      return const SizedBox.shrink();
    }
    final question = widget.questions[widget.currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '문제 다시 보기',
                  style: Typo.headingStrong(context, color: colors.gray900),
                ),
                Row(
                  children: [
                    Semantics(
                      identifier: 'mock-exam-result-previous',
                      label: '이전 문제 보기',
                      button: true,
                      child: GestureDetector(
                      onTap: widget.currentIndex > 0 ? widget.onPrevious : null,
                      child: Opacity(
                        opacity: widget.currentIndex > 0 ? 1.0 : 0.3,
                        child: Assets.icons.arrowBackIos.svg(
                          width: responsive.mediumIconSize,
                          height: responsive.mediumIconSize,
                          colorFilter: ColorFilter.mode(
                            colors.gray900,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      ),
                    ),
                    SizedBox(width: 8 * responsive.scaleFactor),
                    Text(
                      '${widget.currentIndex + 1}',
                      style: Typo.titleStrong(context, color: colors.gray900),
                    ),
                    SizedBox(width: 8 * responsive.scaleFactor),
                    Semantics(
                      identifier: 'mock-exam-result-next',
                      label: '다음 문제 보기',
                      button: true,
                      child: GestureDetector(
                      onTap: widget.currentIndex < widget.questions.length - 1
                          ? widget.onNext
                          : null,
                      child: Opacity(
                        opacity:
                            widget.currentIndex < widget.questions.length - 1
                            ? 1.0
                            : 0.3,
                        child: Assets.icons.arrowForwardIos.svg(
                          width: responsive.mediumIconSize,
                          height: responsive.mediumIconSize,
                          colorFilter: ColorFilter.mode(
                            colors.gray900,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10 * responsive.scaleFactor),
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            identifier: 'mock-exam-view-all',
            label: '전체 문제 보기',
            button: true,
            child: CustomButton(
            text: '전체보기',
            size: ButtonSize.small,
            theme: CustomButtonTheme.grayscale,
            onPressed: widget.onViewAllQuestions,
            ),
          ),
        ),
        SizedBox(height: 12 * responsive.scaleFactor),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(32 * responsive.scaleFactor),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
            border: Border.all(color: colors.gray300),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${question.number}.',
                        style: Typo.headingStrong(
                          context,
                          color: colors.gray900,
                        ),
                      ),
                      SizedBox(width: 10 * responsive.scaleFactor),
                      Expanded(
                        child: Text(
                          question.text,
                          style: Typo.bodyStrong(
                            context,
                            color: colors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32 * responsive.scaleFactor),
                  ...question.choices.map((choice) {
                    final isChoiceCorrect = choice.isCorrect;
                    final wasSelected =
                        question.selectedAnswer == choice.number;

                    Color bgColor = colors.gray0;
                    Color borderColor = colors.gray900;
                    Color numBgColor = colors.gray30;
                    bool isBold = false;

                    if (wasSelected && !isChoiceCorrect) {
                      bgColor = colors.redLightHover;
                      borderColor = colors.redNormalHover;
                      numBgColor = colors.redLightActive;
                      isBold = true;
                    } else if (wasSelected && isChoiceCorrect) {
                      bgColor = colors.greenLightHover;
                      borderColor = colors.greenNormalHover;
                      numBgColor = colors.greenLightActive;
                      isBold = true;
                    } else if (!wasSelected && isChoiceCorrect) {
                      bgColor = colors.gray0;
                      borderColor = colors.greenNormalHover;
                      numBgColor = colors.greenLightActive;
                      isBold = true;
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 10 * responsive.scaleFactor),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.choicePaddingH,
                              vertical: responsive.choicePaddingV,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: responsive.smallNumberBadgeSize,
                                  height: responsive.smallNumberBadgeSize,
                                  decoration: BoxDecoration(
                                    color: numBgColor,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${choice.number}',
                                    style: Typo.footnoteRegular(
                                      context,
                                      color: colors.gray900,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * responsive.scaleFactor),
                                Expanded(
                                  child: Text(
                                    choice.text,
                                    style: isBold
                                        ? Typo.footnoteStrong(
                                            context,
                                            color: colors.gray900,
                                          )
                                        : Typo.footnoteRegular(
                                            context,
                                            color: colors.gray900,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (question.selectedAnswer != choice.number &&
                              isChoiceCorrect)
                            Positioned(
                              top: -10 * responsive.scaleFactor,
                              right: -10 * responsive.scaleFactor,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4 * responsive.scaleFactor,
                                  vertical: 1 * responsive.scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.greenLightHover,
                                  borderRadius: BorderRadius.circular(6 * responsive.scaleFactor),
                                  border: Border.all(
                                    color: colors.greenNormalHover,
                                  ),
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
                    );
                  }),
                  SizedBox(height: 16 * responsive.scaleFactor),
                  Text(
                    '해설',
                    style: Typo.footnoteStrong(context, color: colors.gray900),
                  ),
                  SizedBox(height: 4 * responsive.scaleFactor),
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.explanationPaddingH,
                          vertical: responsive.explanationPaddingV,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                          border: Border.all(color: colors.gray300),
                        ),
                        child: ImageFiltered(
                          imageFilter: _showExplanation
                              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                              : ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Text(
                            question.explanation,
                            style: Typo.footnoteRegular(
                              context,
                              color: colors.gray900,
                            ),
                          ),
                        ),
                      ),
                      if (!_showExplanation)
                        Positioned.fill(
                          child: Center(
                            child: Semantics(
                              identifier: 'mock-exam-show-explanation',
                              label: '해설 보기',
                              button: true,
                              child: CustomButton(
                              text: '해설보기',
                              size: ButtonSize.small,
                              theme: CustomButtonTheme.primary,
                              leftIcon: Assets.icons.visibility,
                              onPressed: () {
                                setState(() {
                                  _showExplanation = true;
                                });
                              },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (question.isCorrect != null && question.isCorrect!)
                Positioned(
                  top: -32 * responsive.scaleFactor,
                  left: -17 * responsive.scaleFactor,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2 * responsive.scaleFactor,
                      vertical: 2 * responsive.scaleFactor,
                    ).copyWith(top: 12 * responsive.scaleFactor),
                    decoration: BoxDecoration(
                      color: colors.greenNormal,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(3 * responsive.scaleFactor),
                        bottomRight: Radius.circular(3 * responsive.scaleFactor),
                      ),
                    ),
                    child: Assets.icons.check.svg(
                      width: 12 * responsive.scaleFactor,
                      height: 12 * responsive.scaleFactor,
                      colorFilter: ColorFilter.mode(
                        colors.gray0,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              if (question.isCorrect != null && !question.isCorrect!)
                Positioned(
                  top: -32 * responsive.scaleFactor,
                  left: -17 * responsive.scaleFactor,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2 * responsive.scaleFactor,
                      vertical: 2 * responsive.scaleFactor,
                    ).copyWith(top: 12 * responsive.scaleFactor),
                    decoration: BoxDecoration(
                      color: colors.redNormal,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(3 * responsive.scaleFactor),
                        bottomRight: Radius.circular(3 * responsive.scaleFactor),
                      ),
                    ),
                    child: Assets.icons.close.svg(
                      width: 12 * responsive.scaleFactor,
                      height: 12 * responsive.scaleFactor,
                      colorFilter: ColorFilter.mode(
                        colors.gray0,
                        BlendMode.srcIn,
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

  Widget _buildBottomButton(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding + 3, vertical: 16 * responsive.scaleFactor),
      child: Semantics(
        identifier: 'mock-exam-complete',
        label: '완료',
        button: true,
        child: CustomButton(
        text: '완료하기',
        size: ButtonSize.large,
        theme: CustomButtonTheme.grayscale,
        onPressed: widget.onComplete,
        ),
      ),
    );
  }
}
