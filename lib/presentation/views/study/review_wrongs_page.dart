import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/study/review_wrongs_repository.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

/// Wrong-answer review queue. Items appear here whenever the user gets a
/// practice or mock-exam question wrong; answering correctly here clears
/// the item from the queue. Single-pass UI — one question at a time, the
/// user picks an option, sees correct/incorrect feedback, then taps
/// "다음" to advance. The queue refreshes on resolve so a freshly-cleared
/// item disappears as you move forward.
class ReviewWrongsPage extends StatefulWidget {
  const ReviewWrongsPage({super.key});

  @override
  State<ReviewWrongsPage> createState() => _ReviewWrongsPageState();
}

class _ReviewWrongsPageState extends State<ReviewWrongsPage> {
  final ReviewWrongsRepository _repo = ReviewWrongsRepository();
  bool _loading = true;
  String? _error;
  List<ReviewWrong> _items = const [];
  int _index = 0;

  // Per-question UI state
  int? _selected;
  bool? _wasCorrect; // null until the user submits
  int? _correctAnswerShown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getWrongs();
      if (!mounted) return;
      setState(() {
        _items = list;
        _index = 0;
        _selected = null;
        _wasCorrect = null;
        _correctAnswerShown = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '약점복습 목록을 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selected == null || _items.isEmpty) return;
    final current = _items[_index];
    try {
      final result = await _repo.resolve(current.questionId, _selected!);
      if (!mounted) return;
      setState(() {
        _wasCorrect = result.resolved;
        _correctAnswerShown = result.correctAnswer;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제출에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  void _next() {
    if (_items.isEmpty) return;
    final wasCorrect = _wasCorrect;
    setState(() {
      // Skip past the just-resolved item; if wrong again, move on but the
      // server keeps the item in the queue so it'll come back on refresh.
      if (_index < _items.length - 1) {
        _index += 1;
      } else {
        _index = 0;
      }
      _selected = null;
      _wasCorrect = null;
      _correctAnswerShown = null;
      // If we cleared one, drop it from local state too so the count is
      // accurate without needing a full refetch.
      if (wasCorrect == true) {
        _items = List.of(_items)..removeAt(_index >= _items.length ? _items.length - 1 : _index);
        if (_index >= _items.length) _index = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.gray20,
        appBar: _appBar(context, colors, '약점복습'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.gray20,
        appBar: _appBar(context, colors, '약점복습'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: Typo.bodyRegular(context, color: colors.gray500)),
              const SizedBox(height: 12),
              CustomButton(
                text: '다시 시도',
                size: ButtonSize.medium,
                theme: CustomButtonTheme.primary,
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: colors.gray20,
        appBar: _appBar(context, colors, '약점복습'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration, size: 48, color: colors.primaryNormal),
                const SizedBox(height: 12),
                Text(
                  '약점복습 목록이 비었어요',
                  style: TextStyle(
                    fontFamily: 'SeoulAlrim',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '모의고사를 한 번 더 보면 새로운 오답이 모일 거예요.',
                  style: Typo.labelRegular(context, color: colors.gray500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final current = _items[_index];
    final answered = _wasCorrect != null;

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _appBar(context, colors, '약점복습 ${_index + 1}/${_items.length}'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current.sourceLabel != null && current.sourceLabel!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${current.subjectName} · ${current.sourceLabel}',
                    style: Typo.labelRegular(context, color: colors.gray400),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.gray0,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.gray70),
                        ),
                        child: Text(
                          current.text,
                          style: TextStyle(
                            fontFamily: 'SeoulAlrim',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: -0.2,
                            color: colors.gray900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...current.choices.map((c) {
                        final isPicked = _selected == c.number;
                        final isCorrect = answered && _correctAnswerShown == c.number;
                        final isWrongPick = answered && isPicked && _wasCorrect == false;
                        Color bg = colors.gray0;
                        Color border = colors.gray70;
                        if (isCorrect) {
                          bg = colors.primaryLight;
                          border = colors.primaryNormal;
                        } else if (isWrongPick) {
                          bg = const Color(0xFFFFEBEB);
                          border = const Color(0xFFE85C5C);
                        } else if (isPicked && !answered) {
                          bg = colors.gray20;
                          border = colors.gray100;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: answered
                                ? null
                                : () => setState(() => _selected = c.number),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border, width: isPicked || isCorrect ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCorrect
                                          ? colors.primaryNormal
                                          : isWrongPick
                                              ? const Color(0xFFE85C5C)
                                              : (isPicked ? colors.gray100 : colors.gray30),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${c.number}',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.gray0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      c.text,
                                      style: Typo.bodyRegular(context, color: colors.gray900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (answered)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.gray0,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.gray70),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _wasCorrect == true ? '정답이에요!' : '아직 헷갈리네요',
                                  style: TextStyle(
                                    fontFamily: 'SeoulAlrim',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _wasCorrect == true
                                        ? colors.primaryNormal
                                        : const Color(0xFFE85C5C),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (current.explanation.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    current.explanation,
                                    style: Typo.bodyRegular(context, color: colors.gray700)
                                        .copyWith(height: 1.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: answered ? '다음' : '제출',
                  size: ButtonSize.large,
                  theme: CustomButtonTheme.primary,
                  disabled: !answered && _selected == null,
                  onPressed: answered ? _next : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, ThemeColors colors, String title) {
    return AppBar(
      backgroundColor: colors.gray0,
      elevation: 0,
      title: Text(title, style: Typo.titleStrong(context, color: colors.gray900)),
      iconTheme: IconThemeData(color: colors.gray900),
    );
  }
}
