import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/study/practice_study_viewmodel.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';

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
    if (_viewModel.isLoading && !_viewModel.isInitialized) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final q = _viewModel.currentQuestion;
    if (q == null) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: Center(
          child: Text(
            '문제를 불러올 수 없습니다',
            style: Typo.bodyRegular(context, color: colors.gray900),
          ),
        ),
      );
    }
    final hasAnswered = _viewModel.hasAnswered;
    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _buildAppBar(context, colors),
      body: SafeArea(
          child: WillPopScope(
          onWillPop: () async {
            await _viewModel.saveProgress();
            HomeRepository().invalidateCache();
            return true;
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(31, 24, 31, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(context, colors, q),
                          const SizedBox(height: 60),
                          _buildChoices(context, colors, q),
                          const SizedBox(height: 50),
                          if (hasAnswered)
                            _buildExplanation(context, colors, q),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(colors),
                ],
              ),
            ],
          ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () async {
              await _viewModel.saveProgress();
              HomeRepository().invalidateCache();
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Assets.icons.arrowBackIos.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
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
              const SizedBox(width: 15),
              Text(
                _viewModel.progressText,
                style: Typo.bodyRegular(context, color: colors.gray900),
              ),
              const SizedBox(width: 15),
            ],
          ),
          titleSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, ThemeColors colors, Question q) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${q.number}.',
          style: Typo.titleStrong(context, color: colors.gray900),
        ),
        const SizedBox(width: 10),
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
    final hasAnswered = _viewModel.hasAnswered;
    return Column(
      children: q.choices
          .map<Widget>(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildChoiceItem(context, colors, q, choice, hasAnswered),
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
    return GestureDetector(
      onTap: hasAnswered ? null : () => _viewModel.selectAnswer(choice.number),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
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
                const SizedBox(width: 8),
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
                top: -30,
                right: -30,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.greenLightHover,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.greenNormalHover),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Assets.icons.check.svg(
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          colors.gray900,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
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
    );
  }

  Widget _buildExplanation(
    BuildContext context,
    ThemeColors colors,
    Question q,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('해설', style: Typo.bodyStrong(context, color: colors.gray900)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.gray70),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 40,
                ),
                child: Text(
                  q.explanation,
                  style: Typo.bodyRegular(context, color: colors.gray900),
                ),
              ),
              if (!_viewModel.showExplanation)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              if (!_viewModel.showExplanation)
                Positioned.fill(
                  child: Center(
                    child: GestureDetector(
                      onTap: _viewModel.toggleExplanation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryNormal,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.primaryNormalHover),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Assets.icons.visibility.svg(
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                colors.gray0,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 4),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(ThemeColors colors) {
    final enabled = _viewModel.hasAnswered;
    final last = !_viewModel.hasNext;
    return Container(
      padding: const EdgeInsets.fromLTRB(33, 12, 33, 20),
      child: SizedBox(
        width: double.infinity,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colors.gray900,
                borderRadius: BorderRadius.circular(12),
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
    );
  }
}
