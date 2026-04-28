import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/exam_session.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class OnboardingExamDatePage extends StatefulWidget {
  const OnboardingExamDatePage({super.key});

  @override
  State<OnboardingExamDatePage> createState() => _OnboardingExamDatePageState();
}

class _OnboardingExamDatePageState extends State<OnboardingExamDatePage> {
  final CatalogRepository _catalog = CatalogRepository();

  List<ExamSession> _sessions = const [];
  String? _selectedSessionId;
  bool _noFixedDate = false;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  String get _certificateId =>
      (Get.arguments as Map<String, dynamic>?)?['certificateId'] as String? ??
      '1';

  ExamSession? get _selectedSession {
    if (_selectedSessionId == null) return null;
    for (final s in _sessions) {
      if (s.id == _selectedSessionId) return s;
    }
    return null;
  }

  bool get _canContinue => _selectedSessionId != null || _noFixedDate;

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _catalog.getExamSessions(_certificateId);
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _loading = false;
        // Empty list → fall back to "정해진 일정 없음" so the user isn't stuck
        // on a screen with nothing to pick.
        if (list.isEmpty) _noFixedDate = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '시험 일정을 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String _dDayLabel(DateTime date) {
    final diff = _daysUntil(date);
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.08;

    return Scaffold(
      backgroundColor: colors.gray10,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        leading: Semantics(
          button: true,
          identifier: 'onboarding-back',
          label: '뒤로 가기',
          child: IconButton(
            icon: Assets.icons.arrowBackIos.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: _buildProgressBar(colors, screenWidth, 0.5),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 24, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '언제까지 합격하고\n싶은지 알려주세요',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      letterSpacing: -0.6,
                      color: colors.gray900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '시험 일정에 맞춰 커리큘럼을 생성할게요.',
                    style: Typo.labelRegular(context, color: colors.gray300),
                  ),
                  const SizedBox(height: 24),
                  _buildBody(colors, context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 32),
            child: CustomButton(
              text: '계속하기',
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: !_canContinue,
              width: double.infinity,
              onPressed: !_canContinue
                  ? null
                  : () {
                      final session = _selectedSession;
                      Get.toNamed(
                        AppRoutes.onboardingHours,
                        arguments: {
                          'certificateId': _certificateId,
                          'examDate': _noFixedDate || session == null
                              ? null
                              : session.examDate.toIso8601String(),
                          'examSessionId':
                              _noFixedDate ? null : session?.id,
                        },
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors colors, BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              _error!,
              style: Typo.bodyRegular(context, color: colors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadSessions,
              child: Text(
                '다시 시도',
                style: Typo.bodyRegular(context, color: colors.primaryNormal),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sessions.isEmpty)
          _EmptySessionsNotice(colors: colors, context: context)
        else
          ..._sessions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SessionCard(
                  session: s,
                  isSelected: _selectedSessionId == s.id && !_noFixedDate,
                  dDay: _dDayLabel(s.examDate),
                  colors: colors,
                  context: context,
                  onTap: () => setState(() {
                    _selectedSessionId = s.id;
                    _noFixedDate = false;
                  }),
                ),
              )),
        const SizedBox(height: 8),
        _NoScheduleToggle(
          selected: _noFixedDate,
          colors: colors,
          context: context,
          onTap: () => setState(() {
            _noFixedDate = !_noFixedDate;
            if (_noFixedDate) _selectedSessionId = null;
          }),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
      ThemeColors colors, double screenWidth, double progress) {
    final maxWidth = screenWidth - 15 - 56;
    return Container(
      height: 12,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: maxWidth * progress,
            height: 12,
            decoration: BoxDecoration(
              color: colors.primaryNormal,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Session Card
// ─────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final ExamSession session;
  final bool isSelected;
  final String dDay;
  final ThemeColors colors;
  final BuildContext context;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.isSelected,
    required this.dDay,
    required this.colors,
    required this.context,
    required this.onTap,
  });

  static const _weekdayKor = ['월', '화', '수', '목', '금', '토', '일'];

  String get _dateLabel {
    final d = session.examDate;
    final w = _weekdayKor[d.weekday - 1];
    return '${d.year}년 ${d.month}월 ${d.day}일 ($w)';
  }

  String get _titleLabel {
    final round = session.roundNumber;
    if (round != null) return '$round회 · ${session.examType}';
    return session.examType;
  }

  @override
  Widget build(BuildContext ctx) {
    return Semantics(
      button: true,
      identifier: 'onboarding-session-${session.id}',
      label: '$_titleLabel $_dateLabel',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryLight : colors.gray0,
            border: Border.all(
              color: isSelected ? colors.primaryNormal : colors.gray30,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          colors.primaryNormal.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _titleLabel,
                          style: Typo.labelRegular(context,
                              color: isSelected
                                  ? colors.primaryNormal
                                  : colors.gray500),
                        ),
                        if (session.isEstimated) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.gray20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '예정',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.gray400,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLabel,
                      style: TextStyle(
                        fontFamily: 'SeoulAlrim',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        letterSpacing: -0.3,
                        color: colors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primaryNormal : colors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dDay,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: colors.gray0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State Notice
// ─────────────────────────────────────────────
class _EmptySessionsNotice extends StatelessWidget {
  final ThemeColors colors;
  final BuildContext context;

  const _EmptySessionsNotice({required this.colors, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.gray20,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.gray30),
      ),
      child: Text(
        '아직 등록된 시험 일정이 없어요.\n‘정해진 일정 없음’으로 시작해 볼까요?',
        style: Typo.bodyRegular(context, color: colors.gray500),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// No Schedule Toggle
// ─────────────────────────────────────────────
class _NoScheduleToggle extends StatelessWidget {
  final bool selected;
  final ThemeColors colors;
  final BuildContext context;
  final VoidCallback onTap;

  const _NoScheduleToggle({
    required this.selected,
    required this.colors,
    required this.context,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primaryLight : colors.gray0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primaryNormal : colors.gray30,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? colors.primaryNormal : colors.gray0,
                border: Border.all(
                  color: selected ? colors.primaryNormal : colors.gray100,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? Icon(Icons.check, size: 14, color: colors.gray0)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '정해진 일정 없음',
              style: Typo.bodyRegular(
                context,
                color: selected ? colors.primaryNormal : colors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
