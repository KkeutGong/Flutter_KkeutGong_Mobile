import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/exam_session.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_login_prompt_page.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

/// "Applying onboarding" loading screen. Runs after the container page
/// persists pending values to SharedPreferences and before we ask the user
/// to log in. Resolves the human-readable labels for the four picks against
/// the live catalog (cert name, exam-session round, hours/style strings) so
/// the next page can show a confirmation card without flashing blanks.
///
/// The screen also enforces a minimum visible duration so the transition
/// feels intentional even when the network calls return instantly.
class OnboardingLoadingPage extends StatefulWidget {
  const OnboardingLoadingPage({super.key});

  @override
  State<OnboardingLoadingPage> createState() => _OnboardingLoadingPageState();
}

class _OnboardingLoadingPageState extends State<OnboardingLoadingPage>
    with SingleTickerProviderStateMixin {
  static const _minVisibleDuration = Duration(milliseconds: 1400);
  static const _statusMessages = [
    '온보딩 정보를 적용하고 있어요',
    '맞춤 커리큘럼을 준비하고 있어요',
    '거의 다 됐어요',
  ];

  final CatalogRepository _catalog = CatalogRepository();
  late final AnimationController _spinnerController;
  Timer? _statusTimer;
  int _statusIdx = 0;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      setState(() {
        _statusIdx = (_statusIdx + 1) % _statusMessages.length;
      });
    });
    _runApply();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _runApply() async {
    final stopwatch = Stopwatch()..start();
    final summary = await _resolveSummary();
    final remaining = _minVisibleDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingLoginPromptPage(
          certName: summary.certName,
          examLabel: summary.examLabel,
          hoursLabel: summary.hoursLabel,
          styleLabel: summary.styleLabel,
        ),
      ),
    );
  }

  static const Map<int, String> _hoursIntToText = {
    1: '5분',
    2: '10분',
    4: '30분',
    7: '1시간',
    14: '2시간 이상',
  };

  Future<_OnboardingSummary> _resolveSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final certId = prefs.getString('pending_onboarding_certificateId');
    final examDate = prefs.getString('pending_onboarding_examDate');
    final examSessionId =
        prefs.getString('pending_onboarding_examSessionId');
    final hoursPerWeek = prefs.getInt('pending_onboarding_hoursPerWeek');
    final styleText = prefs.getString('pending_onboarding_style');

    String? certName;
    String? examLabel;
    if (certId != null) {
      try {
        final certs = await _catalog.getCertificates();
        Certificate? match;
        for (final c in certs) {
          if (c.id == certId) {
            match = c;
            break;
          }
        }
        certName = match?.name;
        if (examSessionId != null && match != null) {
          final sessions = await _catalog.getExamSessions(match.id);
          for (final s in sessions) {
            if (s.id == examSessionId) {
              examLabel = _formatSession(s);
              break;
            }
          }
        }
      } catch (_) {
        // Best-effort — the prompt page will retry from prefs if these stay null.
      }
    }
    if (examLabel == null && examDate != null) {
      try {
        final d = DateTime.parse(examDate);
        examLabel = '${d.year}년 ${d.month}월 ${d.day}일';
      } catch (_) {
        examLabel = examDate;
      }
    }
    examLabel ??= '정해진 일정 없음';

    return _OnboardingSummary(
      certName: certName,
      examLabel: examLabel,
      hoursLabel: hoursPerWeek != null
          ? (_hoursIntToText[hoursPerWeek] ?? '$hoursPerWeek시간/주')
          : null,
      styleLabel: styleText,
    );
  }

  String _formatSession(ExamSession s) {
    final d = s.examDate;
    final round = s.roundNumber;
    final dateStr = '${d.year}년 ${d.month}월 ${d.day}일';
    return round != null ? '$round회 · $dateStr' : dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(colors.primaryNormal),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _statusMessages[_statusIdx],
                  key: ValueKey<int>(_statusIdx),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SeoulAlrim',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.4,
                    color: colors.gray900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려 주세요',
                style: Typo.bodyRegular(context).copyWith(
                  color: colors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSummary {
  final String? certName;
  final String? examLabel;
  final String? hoursLabel;
  final String? styleLabel;

  const _OnboardingSummary({
    required this.certName,
    required this.examLabel,
    required this.hoursLabel,
    required this.styleLabel,
  });
}
