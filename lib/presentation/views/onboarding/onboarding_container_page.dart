import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<Map<String, dynamic>> _stepData = [
    {
      'title': '어떤 자격증을 준비중인지 알려주세요',
      'subtitle': '나중에 다른 자격증도 공부할 수 있어요.',
      'hasInfoIcon': true,
      'paddingLeft': 30.0,
      'options': [
        {'icon': Assets.icons.desktopMac, 'text': '컴퓨터활용능력 2급'},
        {'icon': Assets.icons.menuBook, 'text': '한국사능력검정시험 심화'},
        {'icon': Assets.icons.memory, 'text': '정보처리기능사'},
      ],
    },
    {
      'title': '언제까지 합격하고 싶은지 알려주세요',
      'subtitle': '시험 일정에 맞춰 커리큘럼을 생성할게요.',
      'hasInfoIcon': false,
      'paddingLeft': 30.0,
      'options': [
        {'text': '2025년 11월 23일'},
        {'text': '2026년 3월 20일'},
        {'text': '정해진 일정 없음'},
      ],
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

  // Maps option text to certificateId matching backend externalIds
  static const Map<String, String> _certTextToId = {
    '컴퓨터활용능력 2급': '2',
    '한국사능력검정시험 심화': '3',
    '정보처리기능사': '1',
  };

  // Maps hours option text to hoursPerWeek int
  static const Map<String, int> _hoursTextToInt = {
    '5분': 1,
    '10분': 1,
    '30분': 1,
    '1시간': 7,
    '2시간 이상': 14,
  };

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
    final examText = _pendingSelections[1];
    final hoursText = _pendingSelections[2];
    final styleText = _pendingSelections[3];

    if (certText != null) {
      final certId = _certTextToId[certText] ?? '1';
      await prefs.setString('pending_onboarding_certificateId', certId);
    }
    if (examText != null && examText != '정해진 일정 없음') {
      await prefs.setString('pending_onboarding_examDate', examText);
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
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Assets.icons.arrowBackIos.svg(
                width: 24.0,
                height: 24.0,
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
              onPressed: _previousStep,
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
                  const SizedBox(height: 60),
                  if (isNotificationStep)
                    _buildNotificationContent(colors, screenWidth)
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
          style: Typo.headingStrong(context).copyWith(
            color: colors.gray900,
          ),
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
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 67,
      ),
      child: CustomButton(
        text: '계속하기',
        size: ButtonSize.large,
        theme: CustomButtonTheme.grayscale,
        disabled: !isNotificationStep && selectedValue == null,
        width: double.infinity,
        onPressed:
            (isNotificationStep || selectedValue != null) ? _nextStep : null,
      ),
    );
  }
}
