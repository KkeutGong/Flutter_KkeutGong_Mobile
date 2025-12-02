import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/domain/models/study/exam_result.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/study/mock_exam_viewmodel.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubmitConfirmationModal(
        unansweredCount: _viewModel.unansweredCount,
        onSubmit: _viewModel.submitExam,
      ),
    );
  }

  void _showAllQuestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

    if (_viewModel.isLoading && !_viewModel.isInitialized) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_viewModel.state == ExamState.ready) {
      return _StartModal(
        examName: widget.examName,
        timeLimitMinutes: widget.timeLimitMinutes,
        onStart: _viewModel.startExam,
        onClose: () => Navigator.of(context).pop(),
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
      );
    }

    return _ExamPage(
      questions: _viewModel.questions,
      currentIndex: _viewModel.currentIndex,
      remainingSeconds: _viewModel.remainingSeconds,
      onSelectAnswer: _viewModel.selectAnswer,
      onSubmit: _showSubmitConfirmation,
      onViewAllQuestions: _showAllQuestions,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

class _StartModal extends StatelessWidget {
  final String examName;
  final int timeLimitMinutes;
  final VoidCallback onStart;
  final VoidCallback onClose;

  const _StartModal({
    required this.examName,
    required this.timeLimitMinutes,
    required this.onStart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Assets.icons.close.svg(
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.gray0,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.gray70),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '안내사항',
                          style: Typo.headingStrong(context, color: colors.gray900),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoRow(context, colors, '시험명', examName),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, colors, '제한시간', '$timeLimitMinutes분'),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, colors, '문제수', '100문제'),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: onStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: colors.primaryNormal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '시험 응시하기',
                                style: Typo.bodyRegular(context, color: colors.gray0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, ThemeColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Typo.bodyRegular(context, color: colors.gray300),
        ),
        Text(
          value,
          style: Typo.bodyStrong(context, color: colors.gray900),
        ),
      ],
    );
  }
}

class _ExamPage extends StatelessWidget {
  final List<Question> questions;
  final int currentIndex;
  final int remainingSeconds;
  final Function(int) onSelectAnswer;
  final VoidCallback onSubmit;
  final VoidCallback onViewAllQuestions;
  final VoidCallback onClose;

  const _ExamPage({
    required this.questions,
    required this.currentIndex,
    required this.remainingSeconds,
    required this.onSelectAnswer,
    required this.onSubmit,
    required this.onViewAllQuestions,
    required this.onClose,
  });

  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    return '$minutes분';
  }

  bool get _allAnswered => questions.every((q) => q.selectedAnswer != null);

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(context, colors, question),
                    const SizedBox(height: 16),
                    _buildChoices(context, colors, question),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Assets.icons.close.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.redLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Assets.icons.schedule.svg(
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(colors.redNormal, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '남은시간: $_formattedTime',
                      style: Typo.footnoteStrong(context, color: colors.redNormal),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_allAnswered)
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primaryNormal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '제출하기',
                  style: Typo.footnoteStrong(context, color: colors.gray0),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.gray70,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '제출',
                  style: Typo.footnoteStrong(context, color: colors.gray0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, ThemeColors colors, Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.gray20,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${question.number}번',
              style: Typo.footnoteStrong(context, color: colors.gray600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: Typo.bodyRegular(context, color: colors.gray900),
          ),
        ],
      ),
    );
  }

  Widget _buildChoices(BuildContext context, ThemeColors colors, Question question) {
    return Column(
      children: question.choices.map((choice) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildChoiceItem(context, colors, question, choice),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceItem(
    BuildContext context,
    ThemeColors colors,
    Question question,
    Choice choice,
  ) {
    final isSelected = question.selectedAnswer == choice.number;

    return GestureDetector(
      onTap: () => onSelectAnswer(choice.number),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryLight : colors.gray0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primaryNormal : colors.gray70,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryNormal : colors.gray20,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${choice.number}',
                style: Typo.footnoteStrong(
                  context,
                  color: isSelected ? colors.gray0 : colors.gray600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                choice.text,
                style: Typo.bodyRegular(context, color: colors.gray900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.gray0,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: colors.gray70),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentIndex + 1}/${questions.length}',
                    style: Typo.footnoteStrong(context, color: colors.gray900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onViewAllQuestions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.gray900,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '전체보기',
                style: Typo.footnoteStrong(context, color: colors.gray0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitConfirmationModal extends StatelessWidget {
  final int unansweredCount;
  final VoidCallback onSubmit;

  const _SubmitConfirmationModal({
    required this.unansweredCount,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '시험을 제출하시겠습니까?',
            style: Typo.headingStrong(context, color: colors.gray900),
          ),
          const SizedBox(height: 16),
          if (unansweredCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.redLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '풀지않은문제: $unansweredCount문제',
                style: Typo.labelRegular(context, color: colors.redNormal),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.gray50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '취소',
                      style: Typo.bodyRegular(context, color: colors.gray900),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSubmit();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.primaryNormal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '제출하기',
                      style: Typo.bodyRegular(context, color: colors.gray0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  '전체보기',
                  style: Typo.headingStrong(context, color: colors.gray900),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Assets.icons.close.svg(
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final isCurrent = index == currentIndex;
                final hasAnswer = question.selectedAnswer != null;

                Color backgroundColor = colors.gray20;
                Color textColor = colors.gray600;
                Color borderColor = colors.gray70;

                if (isReviewMode && question.isCorrect != null) {
                  if (question.isCorrect!) {
                    backgroundColor = colors.greenLightHover;
                    borderColor = colors.greenNormal;
                    textColor = colors.greenNormal;
                  } else {
                    backgroundColor = colors.redLightHover;
                    borderColor = colors.redNormal;
                    textColor = colors.redNormal;
                  }
                } else if (hasAnswer) {
                  backgroundColor = colors.primaryLight;
                  borderColor = colors.primaryNormal;
                  textColor = colors.primaryNormal;
                }

                if (isCurrent) {
                  borderColor = colors.gray900;
                }

                return GestureDetector(
                  onTap: () => onSelect(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: Typo.labelStrong(context, color: textColor),
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

class _ResultPage extends StatelessWidget {
  final ExamResult result;
  final List<Question> questions;
  final int currentIndex;
  final VoidCallback onViewAllQuestions;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  const _ResultPage({
    required this.result,
    required this.questions,
    required this.currentIndex,
    required this.onViewAllQuestions,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
  });

  String get _formattedTime {
    final minutes = result.elapsedTime.inMinutes;
    final seconds = result.elapsedTime.inSeconds % 60;
    return '$minutes분 $seconds초';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colors),
              const SizedBox(height: 24),
              _buildSummaryCard(context, colors),
              const SizedBox(height: 16),
              _buildSubjectScores(context, colors),
              const SizedBox(height: 16),
              _buildQuestionReview(context, colors),
              const SizedBox(height: 24),
              _buildCompleteButton(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeColors colors) {
    return Row(
      children: [
        Text(
          '시험 결과',
          style: Typo.titleStrong(context, color: colors.gray900),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, ThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '학습개요',
            style: Typo.headingStrong(context, color: colors.gray900),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context, colors, '총문제수', '${result.totalQuestions}문제',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  context, colors, '맞은문제수', '${result.correctCount}문제',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context, colors, '걸린시간', _formattedTime,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  colors,
                  '합격여부',
                  result.isPassed ? '합격' : '불합격',
                  valueColor: result.isPassed ? colors.greenNormal : colors.redNormal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    ThemeColors colors,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Typo.footnoteRegular(context, color: colors.gray300),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Typo.headingStrong(context, color: valueColor ?? colors.gray900),
        ),
      ],
    );
  }

  Widget _buildSubjectScores(BuildContext context, ThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '과목별 점수',
            style: Typo.headingStrong(context, color: colors.gray900),
          ),
          const SizedBox(height: 16),
          ...result.subjectScores.entries.map((entry) {
            final score = entry.value;
            final percentage = (score.accuracy * 100).round();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      score.name,
                      style: Typo.labelRegular(context, color: colors.gray900),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.gray50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: score.accuracy,
                        child: Container(
                          decoration: BoxDecoration(
                            color: percentage >= 60 ? colors.greenNormal : colors.redNormal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$percentage점',
                      style: Typo.labelStrong(
                        context,
                        color: percentage >= 60 ? colors.greenNormal : colors.redNormal,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(BuildContext context, ThemeColors colors) {
    final question = questions[currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '문제다시보기',
                style: Typo.headingStrong(context, color: colors.gray900),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAllQuestions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.gray900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '전체보기',
                    style: Typo.footnoteStrong(context, color: colors.gray0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: currentIndex > 0 ? onPrevious : null,
                child: Opacity(
                  opacity: currentIndex > 0 ? 1.0 : 0.3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.gray20,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Assets.icons.arrowBackIos.svg(
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: question.isCorrect == true ? colors.greenLight : colors.redLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${currentIndex + 1}번 ${question.isCorrect == true ? "정답" : "오답"}',
                  style: Typo.labelStrong(
                    context,
                    color: question.isCorrect == true ? colors.greenNormal : colors.redNormal,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: currentIndex < questions.length - 1 ? onNext : null,
                child: Opacity(
                  opacity: currentIndex < questions.length - 1 ? 1.0 : 0.3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.gray20,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Assets.icons.arrowForwardIos.svg(
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.gray20,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: Typo.bodyRegular(context, color: colors.gray900),
                ),
                const SizedBox(height: 12),
                ...question.choices.map((choice) {
                  final isCorrect = choice.isCorrect;
                  final wasSelected = question.selectedAnswer == choice.number;
                  
                  Color textColor = colors.gray600;
                  if (isCorrect) {
                    textColor = colors.greenNormal;
                  } else if (wasSelected) {
                    textColor = colors.redNormal;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${choice.number}. ${choice.text}',
                          style: Typo.labelRegular(context, color: textColor),
                        ),
                        if (isCorrect)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.greenNormal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '정답',
                                style: Typo.captionStrong(context, color: colors.gray0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context, ThemeColors colors) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onComplete,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: colors.primaryNormal,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '완료하기',
            style: Typo.bodyRegular(context, color: colors.gray0),
          ),
        ),
      ),
    );
  }
}
