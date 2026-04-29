import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/study/explain_repository.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

/// Bottom sheet shown the moment a user answers a question — practice,
/// mock, or review. Surfaces the AI explanation tailored to the picked
/// choice, with the static `Question.explanation` always rendering first
/// as an instant fallback so the sheet never feels empty during the
/// network call. Use [AnswerFeedbackSheet.show] to open it.
class AnswerFeedbackSheet extends StatefulWidget {
  final String questionId;
  final int selectedAnswer;
  /// Static explanation we already have on the device — shown immediately
  /// while the AI version streams in. Null when the question doesn't ship
  /// with one.
  final String? localExplanation;

  const AnswerFeedbackSheet({
    super.key,
    required this.questionId,
    required this.selectedAnswer,
    this.localExplanation,
  });

  static Future<void> show(
    BuildContext context, {
    required String questionId,
    required int selectedAnswer,
    String? localExplanation,
  }) {
    final colors = ThemeColors.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.gray0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AnswerFeedbackSheet(
        questionId: questionId,
        selectedAnswer: selectedAnswer,
        localExplanation: localExplanation,
      ),
    );
  }

  @override
  State<AnswerFeedbackSheet> createState() => _AnswerFeedbackSheetState();
}

class _AnswerFeedbackSheetState extends State<AnswerFeedbackSheet> {
  final ExplainRepository _repo = ExplainRepository();
  QuestionExplanation? _explanation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _repo.explain(widget.questionId, widget.selectedAnswer);
      if (!mounted) return;
      setState(() {
        _explanation = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _explanation = QuestionExplanation(
          text: widget.localExplanation ??
              '아직 자세한 풀이를 준비하지 못했어요. 정답을 먼저 확인하고 관련 개념을 다시 살펴봐 주세요.',
          source: 'fallback',
          correctAnswer: null,
          isCorrect: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isCorrect = _explanation?.isCorrect ?? false;
    final correct = _explanation?.correctAnswer;
    final headerText = isCorrect ? '정답이에요!' : '아직 헷갈려요';
    final headerColor = isCorrect ? colors.primaryNormal : const Color(0xFFE85C5C);

    final bodyText = !_loading && _explanation != null
        ? _explanation!.text
        : (widget.localExplanation ?? '');
    final source = _explanation?.source;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.gray70,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.lightbulb_outline,
                  color: headerColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: TextStyle(
                    fontFamily: 'SeoulAlrim',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: headerColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (correct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.gray20,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '정답 $correct번',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.gray700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.gray20,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.gray30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loading)
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(colors.primaryNormal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI가 풀이를 작성하는 중',
                          style: Typo.labelRegular(context, color: colors.gray500),
                        ),
                      ],
                    ),
                  if (bodyText.isNotEmpty) ...[
                    if (_loading) const SizedBox(height: 10),
                    Text(
                      bodyText,
                      style: Typo.bodyRegular(context, color: colors.gray900)
                          .copyWith(height: 1.6),
                    ),
                  ],
                  if (source != null && !_loading) ...[
                    const SizedBox(height: 8),
                    Text(
                      source == 'qwen'
                          ? 'AI 튜터가 작성한 풀이예요'
                          : source == 'cache'
                              ? '저장된 AI 풀이예요'
                              : '기본 풀이예요',
                      style: Typo.labelRegular(context, color: colors.gray400),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: '확인',
                size: ButtonSize.large,
                theme: CustomButtonTheme.primary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
