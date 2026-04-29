import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/exam_session.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_loading_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingContainerPage extends StatefulWidget {
  const OnboardingContainerPage({super.key});

  @override
  State<OnboardingContainerPage> createState() =>
      _OnboardingContainerPageState();
}

class _OnboardingContainerPageState extends State<OnboardingContainerPage> {
  int _currentStep = 0;
  String? selectedValue;
  // Stores the selected value for each step index (0=cert, 1=date, 2=hours, 3=style)
  final Map<int, String> _pendingSelections = {};

  // Date picker state for step 1. The user normally picks a real exam session
  // (78회 5/23, 79회 8/8, …) from `_examSessions`; the free-form calendar
  // (`_pickedExamDate`) is only kept as a fallback for the "정해진 일정 없음"
  // toggle and for certs that don't have any sessions seeded yet.
  DateTime? _pickedExamDate;
  bool _noFixedDate = false;
  List<ExamSession> _examSessions = const [];
  String? _selectedSessionId;
  bool _sessionsLoading = false;
  String? _sessionsError;
  String? _sessionsLoadedForCertId;

  ExamSession? get _selectedSession {
    if (_selectedSessionId == null) return null;
    for (final s in _examSessions) {
      if (s.id == _selectedSessionId) return s;
    }
    return null;
  }

  // Certificate catalog loaded from /catalog/certificates. Populated lazily so
  // adding a new cert in the backend never requires a mobile release.
  final CatalogRepository _catalog = CatalogRepository();
  bool _certsLoading = true;
  String? _certsError;
  Map<String, Certificate> _certByName = const {};

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _certsLoading = true;
      _certsError = null;
    });
    try {
      final certs = await _catalog.getCertificates();
      if (!mounted) return;
      _certByName = {for (final c in certs) c.name: c};
      _stepData[0]['options'] = certs
          .map((c) => {'icon': _certIconAsset(c.icon), 'text': c.name})
          .toList();
      setState(() => _certsLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _certsError = '자격증 목록을 불러오지 못했어요.';
        _certsLoading = false;
      });
    }
  }

  // Backend returns the icon as a string identifier; map it to a bundled SVG.
  // Falls back to the memory icon for unknown identifiers so a new backend
  // value never blanks the row.
  dynamic _certIconAsset(String iconName) {
    switch (iconName) {
      case 'desktop_mac':
        return Assets.icons.desktopMac;
      case 'menu_book':
        return Assets.icons.menuBook;
      case 'memory':
      default:
        return Assets.icons.memory;
    }
  }

  final List<Map<String, dynamic>> _stepData = [
    {
      'title': '어떤 자격증을 준비중인지 알려주세요',
      'subtitle': '나중에 다른 자격증도 공부할 수 있어요.',
      'hasInfoIcon': true,
      'paddingLeft': 30.0,
      'options': <Map<String, dynamic>>[],
    },
    {
      'title': '언제까지 합격하고 싶은지 알려주세요',
      'subtitle': '시험 일정에 맞춰 커리큘럼을 생성할게요.',
      'hasInfoIcon': false,
      'paddingLeft': 30.0,
      'isDatePickerStep': true,
    },
    {
      'title': '하루에 공부할 수 있는 시간을 알려주세요',
      'subtitle': '공부 시간을 바탕으로 커리큘럼을 생성할게요.',
      'hasInfoIcon': false,
      'paddingLeft': 31.0,
      'options': [
        {'icon': Assets.icons.timer, 'text': '5분'},
        {'icon': Assets.icons.timer, 'text': '10분'},
        {'icon': Assets.icons.timer, 'text': '30분'},
        {'icon': Assets.icons.timer, 'text': '1시간'},
        {'icon': Assets.icons.timer, 'text': '2시간 이상'},
      ],
    },
    {
      'title': '선호하는 학습 스타일을 알려주세요',
      'subtitle': '학습 스타일을 바탕으로 커리큘럼을 생성할게요.',
      'hasInfoIcon': false,
      'paddingLeft': 31.0,
      'options': [
        {'icon': Assets.icons.flashOn, 'text': '빠른 문제 풀이'},
        {'icon': Assets.icons.draw, 'text': '개념 위주'},
        {'icon': Assets.icons.coPresent, 'text': '해설 위주'},
        {'icon': Assets.icons.rotateLeft, 'text': '반복 학습'},
      ],
    },
    {
      'title': '오늘의 학습, 놓치지 마세요',
      'subtitle': '잊어버리지 않도록 알림으로 하루 학습을 챙겨드릴게요.',
      'hasInfoIcon': false,
      'paddingLeft': 31.0,
      'isNotificationStep': true,
    },
  ];

  // Resolves the user-selected certificate name to the externalId expected by
  // the backend. Falls back to '1' for safety, but the catalog is fetched up
  // front so this should never miss in practice.
  String _certIdForName(String? name) =>
      (name != null ? _certByName[name]?.id : null) ?? '1';

  // Maps daily-minutes option text to weekly hours sent to the backend.
  // Conversion: ceil(minutesPerDay × 7 ÷ 60), with 1 as the floor so a 5-minute
  // pick still gets at least one hour scheduled per week.
  static const Map<String, int> _hoursTextToInt = {
    '5분': 1,
    '10분': 2,
    '30분': 4,
    '1시간': 7,
    '2시간 이상': 14,
  };

  bool get _currentStepComplete {
    final step = _stepData[_currentStep];
    if (step['isDatePickerStep'] == true) {
      return _selectedSessionId != null || _pickedExamDate != null || _noFixedDate;
    }
    if (step['isNotificationStep'] == true) return true;
    return selectedValue != null;
  }

  Future<void> _loadExamSessions(String certId) async {
    if (_sessionsLoadedForCertId == certId && _sessionsError == null) return;
    setState(() {
      _sessionsLoading = true;
      _sessionsError = null;
    });
    try {
      final list = await _catalog.getExamSessions(certId);
      if (!mounted) return;
      setState(() {
        _examSessions = list;
        _sessionsLoadedForCertId = certId;
        _sessionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessionsError = '시험 일정을 불러오지 못했어요.';
        _sessionsLoading = false;
      });
    }
  }

  void _nextStep() async {
    if (_currentStep < _stepData.length - 1) {
      setState(() {
        _currentStep++;
        selectedValue = null;
      });

      // Entering the date-picker step → kick off the session fetch for the
      // cert the user just chose, so the SessionCard list is ready when the
      // step renders.
      if (_currentStep == 1) {
        final certText = _pendingSelections[0];
        if (certText != null) {
          final certId = _certIdForName(certText);
          unawaited(_loadExamSessions(certId));
        }
      }

      if (_currentStep == 4) {
        await _requestNotificationPermission();
      }
    } else {
      await _savePendingOnboarding();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingLoadingPage(),
        ),
      );
    }
  }

  Future<void> _savePendingOnboarding() async {
    // Collect selections from each step's selectedValue by re-reading the
    // current _stepData. Since this container page tracks a single
    // selectedValue per step (resetting on step change), we need the values
    // that were selected at each step. We store them step-by-step.
    // The container page resets selectedValue on each step advance, so we
    // use the _pendingSelections map populated in _buildOptions onTap.
    final prefs = await SharedPreferences.getInstance();
    final certText = _pendingSelections[0];
    final hoursText = _pendingSelections[2];
    final styleText = _pendingSelections[3];

    if (certText != null) {
      final certId = _certIdForName(certText);
      await prefs.setString('pending_onboarding_certificateId', certId);
    }
    final session = _selectedSession;
    if (!_noFixedDate && session != null) {
      await prefs.setString(
        'pending_onboarding_examDate',
        session.examDate.toIso8601String(),
      );
      await prefs.setString('pending_onboarding_examSessionId', session.id);
    } else if (!_noFixedDate && _pickedExamDate != null) {
      await prefs.setString(
        'pending_onboarding_examDate',
        _pickedExamDate!.toIso8601String(),
      );
      await prefs.remove('pending_onboarding_examSessionId');
    } else {
      await prefs.remove('pending_onboarding_examDate');
      await prefs.remove('pending_onboarding_examSessionId');
    }
    if (hoursText != null) {
      final hours = _hoursTextToInt[hoursText] ?? 7;
      await prefs.setInt('pending_onboarding_hoursPerWeek', hours);
    }
    if (styleText != null) {
      await prefs.setString('pending_onboarding_style', styleText);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final currentStatus = await Permission.notification.status;
    if (currentStatus.isGranted) return;
    
    await Permission.notification.request();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        selectedValue = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  double _getProgressWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxProgressWidth = screenWidth - 15 - 56;
    const progressPercentages = [0.167, 0.334, 0.501, 0.668, 0.835];
    return maxProgressWidth * progressPercentages[_currentStep];
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray10,
      appBar: PreferredSize(
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Semantics(
              button: true,
              identifier: 'onboarding-back',
              label: '뒤로 가기',
              child: IconButton(
                icon: Assets.icons.arrowBackIos.svg(
                  width: 24.0,
                  height: 24.0,
                  colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                ),
                onPressed: _previousStep,
              ),
            ),
            title: Container(
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
                    width: _getProgressWidth(),
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: colors.primaryNormal,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildStepContent(colors),
    );
  }

  Widget _buildStepContent(ThemeColors colors) {
    final stepData = _stepData[_currentStep];
    final isNotificationStep = stepData['isNotificationStep'] == true;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.08;

    return Column(
      key: ValueKey(_currentStep),
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                13,
                horizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(colors, stepData),
                  const SizedBox(height: 32),
                  if (isNotificationStep)
                    _buildNotificationContent(colors, screenWidth)
                  else if (stepData['isDatePickerStep'] == true)
                    _buildDatePickerOptions(colors)
                  else if (_currentStep == 0 && (_certsLoading || _certsError != null))
                    _buildCertLoadingState(colors)
                  else
                    _buildOptions(colors, stepData['options']),
                ],
              ),
            ),
          ),
        ),
        _buildBottomButton(colors, isNotificationStep),
      ],
    );
  }

  Widget _buildNotificationContent(ThemeColors colors, double screenWidth) {
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * 0.659;
    final arrowSize = screenWidth * 0.17;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Assets.images.alert.image(
          width: imageWidth,
          height: imageHeight,
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.09),
          child: Assets.icons.arrowUpwardLong.svg(
            width: arrowSize,
            height: arrowSize,
            colorFilter:
                ColorFilter.mode(colors.primaryNormal, BlendMode.srcIn),
          ),
        )
      ],
    );
  }

  Widget _buildTitle(ThemeColors colors, Map<String, dynamic> stepData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepData['title'],
          style: const TextStyle(
            fontFamily: 'SeoulAlrim',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.35,
            letterSpacing: -0.6,
          ).copyWith(color: colors.gray900),
        ),
        SizedBox(height: stepData['hasInfoIcon'] ? 8 : 4),
        if (stepData['hasInfoIcon'])
          Row(
            children: [
              Assets.icons.infoFill.svg(
                width: 18.0,
                height: 18.0,
                colorFilter: ColorFilter.mode(colors.gray300, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                stepData['subtitle'],
                style: Typo.labelRegular(context).copyWith(
                  color: colors.gray300,
                ),
              ),
            ],
          )
        else
          Text(
            stepData['subtitle'],
            style: Typo.labelRegular(context).copyWith(
              color: colors.gray300,
            ),
          ),
      ],
    );
  }

  static String _optionIdentifier(int step, String text) {
    final prefix = ['onboarding-cert', 'onboarding-examdate', 'onboarding-hours', 'onboarding-style'];
    final stepPrefix = step < prefix.length ? prefix[step] : 'onboarding-option';
    final slug = text
        .replaceAll(' ', '-')
        .replaceAll('년', '')
        .replaceAll('월', '')
        .replaceAll('일', '')
        .toLowerCase();
    return '$stepPrefix-$slug';
  }

  Widget _buildCertLoadingState(ThemeColors colors) {
    if (_certsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              _certsError!,
              style: Typo.bodyRegular(context, color: colors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadCertificates,
              child: Text('다시 시도', style: Typo.bodyRegular(context, color: colors.primaryNormal)),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildOptions(ThemeColors colors, List<Map<String, dynamic>> options) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedValue == option['text'];
        final identifier = _optionIdentifier(_currentStep, option['text'] as String);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            button: true,
            identifier: identifier,
            label: option['text'] as String,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedValue = option['text'];
                  _pendingSelections[_currentStep] = option['text'] as String;
                });
              },
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryLight : colors.gray0,
                border: Border.all(
                  color: isSelected ? colors.primaryNormal : colors.gray900,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (option['icon'] != null) ...[
                    option['icon'].svg(
                      width: 24.0,
                      height: 24.0,
                      colorFilter:
                          ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option['text'],
                        style: Typo.bodyRegular(context).copyWith(
                          color: colors.gray900,
                        ),
                      ),
                    ),
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

  Widget _buildBottomButton(ThemeColors colors, bool isNotificationStep) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.088;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        32,
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          text: '계속하기',
          size: ButtonSize.large,
          theme: CustomButtonTheme.grayscale,
          disabled: !_currentStepComplete,
          width: double.infinity,
          onPressed: _currentStepComplete ? _nextStep : null,
        ),
      ),
    );
  }

  Widget _buildDatePickerOptions(ThemeColors colors) {
    if (_sessionsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_sessionsError != null) {
      final certText = _pendingSelections[0];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              _sessionsError!,
              textAlign: TextAlign.center,
              style: Typo.bodyRegular(context, color: colors.gray500),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: certText == null
                  ? null
                  : () => _loadExamSessions(_certIdForName(certText)),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_examSessions.isEmpty)
          Container(
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
          )
        else
          ..._examSessions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContainerSessionCard(
                  session: s,
                  isSelected: _selectedSessionId == s.id && !_noFixedDate,
                  dDay: _formatDDay(s.examDate),
                  colors: colors,
                  onTap: () => setState(() {
                    _selectedSessionId = s.id;
                    _pickedExamDate = null;
                    _noFixedDate = false;
                  }),
                ),
              )),
        const SizedBox(height: 8),

        // ── 정해진 일정 없음 ──
        Semantics(
          button: true,
          identifier: 'onboarding-examdate-no-fixed',
          label: '정해진 일정 없음',
          child: _ContainerNoScheduleToggle(
            selected: _noFixedDate,
            colors: colors,
            onTap: () => setState(() {
              _noFixedDate = !_noFixedDate;
              if (_noFixedDate) {
                _selectedSessionId = null;
                _pickedExamDate = null;
              }
            }),
          ),
        ),
      ],
    );
  }

  String _formatDDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }
}

// ─────────────────────────────────────────────
// No Schedule Toggle (container-local copy)
// ─────────────────────────────────────────────
class _ContainerNoScheduleToggle extends StatelessWidget {
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _ContainerNoScheduleToggle({
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.32,
                color: selected ? colors.primaryNormal : colors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Session Card (real-exam picker)
// ─────────────────────────────────────────────
class _ContainerSessionCard extends StatelessWidget {
  final ExamSession session;
  final bool isSelected;
  final String dDay;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _ContainerSessionCard({
    required this.session,
    required this.isSelected,
    required this.dDay,
    required this.colors,
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
  Widget build(BuildContext context) {
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
                      color: colors.primaryNormal.withValues(alpha: 0.10),
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
