import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
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

  // Date picker state for step 1
  DateTime? _pickedExamDate;
  bool _noFixedDate = false;

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
      return _pickedExamDate != null || _noFixedDate;
    }
    if (step['isNotificationStep'] == true) return true;
    return selectedValue != null;
  }

  void _nextStep() async {
    if (_currentStep < _stepData.length - 1) {
      setState(() {
        _currentStep++;
        selectedValue = null;
      });

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
    if (!_noFixedDate && _pickedExamDate != null) {
      await prefs.setString('pending_onboarding_examDate', _pickedExamDate!.toIso8601String());
    } else {
      await prefs.remove('pending_onboarding_examDate');
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

  // Calendar display month state — initialised lazily on first build
  DateTime _displayMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  bool _displayMonthInitialized = false;

  void _ensureDisplayMonthInitialized() {
    if (!_displayMonthInitialized) {
      final now = DateTime.now();
      _displayMonth = DateTime(now.year, now.month);
      _displayMonthInitialized = true;
    }
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  void _onDayTap(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) return;
    setState(() {
      _pickedExamDate = date;
      _noFixedDate = false;
    });
  }

  Widget _buildDatePickerOptions(ThemeColors colors) {
    _ensureDisplayMonthInitialized();

    final hasDate = _pickedExamDate != null && !_noFixedDate;

    String dateLabel;
    if (_noFixedDate) {
      dateLabel = '정해진 일정 없음';
    } else if (_pickedExamDate == null) {
      dateLabel = '날짜를 선택해 주세요';
    } else {
      dateLabel = '${_pickedExamDate!.year}년 ${_pickedExamDate!.month}월 ${_pickedExamDate!.day}일';
    }

    String? dDayLabel;
    if (_pickedExamDate != null && !_noFixedDate) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(_pickedExamDate!.year, _pickedExamDate!.month, _pickedExamDate!.day);
      final diff = target.difference(today).inDays;
      dDayLabel = diff == 0 ? 'D-Day' : (diff > 0 ? 'D-$diff' : 'D+${-diff}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 선택 날짜 + D-day 배너 ──
        _ContainerSelectedDateBanner(
          label: dateLabel,
          dDay: dDayLabel,
          hasSelection: hasDate || _noFixedDate,
          colors: colors,
        ),

        const SizedBox(height: 16),

        // ── 인라인 캘린더 ──
        AnimatedOpacity(
          opacity: _noFixedDate ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: _noFixedDate,
            child: _ContainerInlineCalendar(
              displayMonth: _displayMonth,
              selectedDate: _pickedExamDate,
              onDayTap: _onDayTap,
              onPrevMonth: _prevMonth,
              onNextMonth: _nextMonth,
              colors: colors,
            ),
          ),
        ),

        const SizedBox(height: 16),

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
              if (_noFixedDate) _pickedExamDate = null;
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Selected Date Banner (container-local copy)
// ─────────────────────────────────────────────
class _ContainerSelectedDateBanner extends StatelessWidget {
  final String label;
  final String? dDay;
  final bool hasSelection;
  final ThemeColors colors;

  const _ContainerSelectedDateBanner({
    required this.label,
    required this.dDay,
    required this.hasSelection,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: hasSelection ? colors.primaryLight : colors.gray20,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSelection ? colors.primaryNormal : colors.gray30,
          width: hasSelection ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SeoulAlrim',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.4,
                color: hasSelection ? colors.primaryNormal : colors.gray100,
              ),
            ),
          ),
          if (dDay != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryNormal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dDay!,
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Inline Calendar (container-local copy)
// ─────────────────────────────────────────────
class _ContainerInlineCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime? selectedDate;
  final void Function(DateTime) onDayTap;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ThemeColors colors;

  const _ContainerInlineCalendar({
    required this.displayMonth,
    required this.selectedDate,
    required this.onDayTap,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.colors,
  });

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _korMonths = [
    '', '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final daysInMonth =
        DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);
    final cells = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) { cells.add(null); }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(displayMonth.year, displayMonth.month, d));
    }
    while (cells.length % 7 != 0) { cells.add(null); }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final cells = _buildCalendarDays();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.gray30, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
      child: Column(
        children: [
          // Month nav header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPrevMonth,
                  icon: Icon(Icons.chevron_left, color: colors.gray400, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Text(
                  '${displayMonth.year}년 ${_korMonths[displayMonth.month]}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                    color: colors.gray900,
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: Icon(Icons.chevron_right, color: colors.gray400, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: _weekdays.map((w) {
                final isSun = w == '일';
                final isSat = w == '토';
                return Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSun
                            ? const Color(0xffFF4035).withValues(alpha: 0.7)
                            : isSat
                                ? colors.primaryNormal.withValues(alpha: 0.7)
                                : colors.gray300,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Day grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: cells.length,
              itemBuilder: (_, index) {
                final date = cells[index];
                if (date == null) return const SizedBox.shrink();

                final isToday = date == today;
                final isSelected = selectedDate != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month &&
                    date.day == selectedDate!.day;
                final isPast = date.isBefore(today);
                final isSunday = date.weekday == DateTime.sunday;
                final isSaturday = date.weekday == DateTime.saturday;

                Color dayTextColor;
                if (isSelected) {
                  dayTextColor = colors.gray0;
                } else if (isPast) {
                  dayTextColor = colors.gray50;
                } else if (isSunday) {
                  dayTextColor = const Color(0xffFF4035).withValues(alpha: 0.85);
                } else if (isSaturday) {
                  dayTextColor = colors.primaryNormal.withValues(alpha: 0.85);
                } else {
                  dayTextColor = colors.gray900;
                }

                return GestureDetector(
                  onTap: isPast ? null : () => onDayTap(date),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primaryNormal
                            : isToday
                                ? colors.primaryLight
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: colors.primaryNormal, width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: dayTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
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
