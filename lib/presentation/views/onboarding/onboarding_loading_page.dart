import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/exam_session.dart';
import 'package:kkeutgong_mobile/presentation/views/auth/login_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';

class OnboardingLoadingPage extends StatefulWidget {
  const OnboardingLoadingPage({super.key});

  @override
  State<OnboardingLoadingPage> createState() => _OnboardingLoadingPageState();
}

class _OnboardingLoadingPageState extends State<OnboardingLoadingPage> {
  final CatalogRepository _catalog = CatalogRepository();
  String? _certName;
  String? _examLabel;
  String? _hoursLabel;
  String? _styleLabel;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  static const Map<int, String> _hoursIntToText = {
    1: '5분',
    2: '10분',
    4: '30분',
    7: '1시간',
    14: '2시간 이상',
  };

  Future<void> _loadSummary() async {
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
        // Best-effort — show what we can.
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

    if (!mounted) return;
    setState(() {
      _certName = certName;
      _examLabel = examLabel;
      _hoursLabel =
          hoursPerWeek != null ? (_hoursIntToText[hoursPerWeek] ?? '$hoursPerWeek시간/주') : null;
      _styleLabel = styleText;
    });
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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final widthRatio = screenWidth / 393;
    final heightRatio = screenHeight / 852;

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 60 * heightRatio),
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 31 * widthRatio),
              child: Text(
                '거의 다 왔어요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SeoulAlrim',
                  fontSize: 36 * widthRatio,
                  fontWeight: FontWeight.w800,
                  height: 1.33,
                  letterSpacing: -1.0 * widthRatio,
                  color: colors.gray900,
                ),
              ),
            ),
            SizedBox(height: 12 * heightRatio),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 31 * widthRatio),
              child: Text(
                '로그인하면 AI가 맞춤 커리큘럼을\n바로 만들어 드릴게요.',
                textAlign: TextAlign.center,
                style: Typo.bodyRegular(context).copyWith(
                  color: colors.gray500,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24 * heightRatio),
            // Hero illustration
            SizedBox(
              width: 240 * widthRatio,
              height: 200 * heightRatio,
              child: Assets.images.mainImage.image(fit: BoxFit.contain),
            ),
            SizedBox(height: 16 * heightRatio),
            // Onboarding summary card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * widthRatio),
              child: _SummaryCard(
                colors: colors,
                certName: _certName,
                examLabel: _examLabel,
                hoursLabel: _hoursLabel,
                styleLabel: _styleLabel,
              ),
            ),
            const Spacer(),
            // CTA
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * widthRatio),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: '로그인하고 시작하기',
                  theme: CustomButtonTheme.primary,
                  size: ButtonSize.large,
                  onPressed: () {
                    Get.offAll(() => const LoginPage());
                  },
                ),
              ),
            ),
            SizedBox(height: 24 * heightRatio),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ThemeColors colors;
  final String? certName;
  final String? examLabel;
  final String? hoursLabel;
  final String? styleLabel;

  const _SummaryCard({
    required this.colors,
    required this.certName,
    required this.examLabel,
    required this.hoursLabel,
    required this.styleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.gray30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(label: '자격증', value: certName, colors: colors),
          _SummaryDivider(colors: colors),
          _SummaryRow(label: '시험일', value: examLabel, colors: colors),
          _SummaryDivider(colors: colors),
          _SummaryRow(label: '학습 시간', value: hoursLabel, colors: colors),
          _SummaryDivider(colors: colors),
          _SummaryRow(label: '학습 스타일', value: styleLabel, colors: colors),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String? value;
  final ThemeColors colors;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            hasValue ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: hasValue ? colors.primaryNormal : colors.gray100,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.gray500,
              letterSpacing: -0.28,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              hasValue ? value! : '—',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasValue ? colors.gray900 : colors.gray100,
                letterSpacing: -0.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  final ThemeColors colors;
  const _SummaryDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: colors.gray20);
  }
}
