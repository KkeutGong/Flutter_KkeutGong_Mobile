import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/curriculum/curriculum_plan.dart';
import 'package:kkeutgong_mobile/domain/models/home/exam_session.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

// Bottom sheet that lets the user change the exam date their curriculum is
// pointing at without redoing the whole onboarding. Fetches the same
// ExamSession list onboarding uses, then re-runs /curricula/generate while
// preserving hoursPerWeek so the only thing that flips is the exam date.
class ExamDateChangeSheet extends StatefulWidget {
  final String certificateId;
  final MyCurriculum? currentCurriculum;

  const ExamDateChangeSheet({
    super.key,
    required this.certificateId,
    required this.currentCurriculum,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String certificateId,
    required MyCurriculum? currentCurriculum,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExamDateChangeSheet(
        certificateId: certificateId,
        currentCurriculum: currentCurriculum,
      ),
    );
  }

  @override
  State<ExamDateChangeSheet> createState() => _ExamDateChangeSheetState();
}

class _ExamDateChangeSheetState extends State<ExamDateChangeSheet> {
  final CatalogRepository _catalog = CatalogRepository();
  final ApiClient _api = ApiClient();

  List<ExamSession> _sessions = const [];
  String? _selectedId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

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
      final list = await _catalog.getExamSessions(widget.certificateId);
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '시험 일정을 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_selectedId == null) return;
    final session = _sessions.firstWhere((s) => s.id == _selectedId);
    setState(() => _submitting = true);
    try {
      // Reuse the onboarding generator. Keeping the existing hoursPerWeek
      // means switching exam date doesn't silently reset the user's pace.
      await _api.post('/curricula/generate', body: {
        'certificateId': widget.certificateId,
        'examSessionId': session.id,
        'examDate': session.examDate.toIso8601String(),
        'hoursPerWeek': widget.currentCurriculum?.hoursPerWeek ?? 7,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '시험일 변경에 실패했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.78;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: colors.gray0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + mq.viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.gray70,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              '시험일을 바꿀까요?',
              style: TextStyle(
                fontFamily: 'SeoulAlrim',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.4,
                color: colors.gray900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '새 시험일에 맞춰 커리큘럼이 자동으로 다시 짜져요.',
              style: Typo.labelRegular(context, color: colors.gray500),
            ),
            const SizedBox(height: 16),
            Flexible(child: _buildBody(colors, context)),
            const SizedBox(height: 12),
            CustomButton(
              text: _submitting ? '적용 중…' : '시험일 변경',
              size: ButtonSize.large,
              theme: CustomButtonTheme.primary,
              disabled: _selectedId == null || _submitting,
              width: double.infinity,
              onPressed: (_selectedId == null || _submitting) ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeColors colors, BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              _error!,
              style: Typo.bodyRegular(context, color: colors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: Text(
                '다시 시도',
                style: Typo.bodyRegular(context, color: colors.primaryNormal),
              ),
            ),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '아직 등록된 시험 일정이 없어요.\n조금 뒤에 다시 시도해 주세요.',
          style: Typo.bodyRegular(context, color: colors.gray500),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = _sessions[i];
        final isSelected = s.id == _selectedId;
        final dDay = _dDayLabel(s.examDate);
        return GestureDetector(
          onTap: () => setState(() => _selectedId = s.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryLight : colors.gray0,
              border: Border.all(
                color: isSelected ? colors.primaryNormal : colors.gray30,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.roundNumber != null
                            ? '${s.roundNumber}회 · ${s.examType}'
                            : s.examType,
                        style: Typo.labelRegular(
                          context,
                          color: isSelected ? colors.primaryNormal : colors.gray500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.examDate.year}년 ${s.examDate.month}월 ${s.examDate.day}일',
                        style: Typo.bodyStrong(context, color: colors.gray900),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primaryNormal : colors.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dDay,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: colors.gray0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }
}
