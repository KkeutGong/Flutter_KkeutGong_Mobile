import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/core/notifications/notification_service.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/study/today_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/streak_info.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/study/today_plan.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final TodayRepository _todayRepository = TodayRepository();

  HomeViewModel(HomeRepository? repository) : _repository = repository ?? HomeRepository();

  TodayPlan? _todayPlan;
  TodayPlan? get todayPlan => _todayPlan;

  HomeData? _homeData;
  HomeData? get homeData => _homeData;

  StreakInfo? get streakInfo => _homeData?.streakInfo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _error;
  String? get error => _error;

  StudyMode _currentMode = StudyMode.concept;
  StudyMode get currentMode => _currentMode;

  int _currentModeIndex = 0;
  int get currentModeIndex => _currentModeIndex;

  final List<StudyMode> _studyModes = [
    StudyMode.concept,
    StudyMode.practice,
    StudyMode.review,
  ];
  List<StudyMode> get studyModes => _studyModes;

  bool _isCertificateDropdownOpen = false;
  bool get isCertificateDropdownOpen => _isCertificateDropdownOpen;

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _repository.getHomeData(forceRefresh: forceRefresh);
      // Today plan is best-effort — a missing curriculum (brand-new account)
      // still lets the home tab render the carousel + cert info.
      try {
        _todayPlan = await _todayRepository.getToday(forceRefresh: forceRefresh);
        // Best-effort: fire any milestone notifications the new plan
        // unlocked (streak, pass-meter, late-day reminder). Failures here
        // never bubble — milestones are nice-to-have on top of the screen.
        try {
          await _maybeFireMilestones(_todayPlan!);
        } catch (_) {
          // ignore
        }
      } catch (_) {
        _todayPlan = null;
      }
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isInitialized = false;
    _todayRepository.invalidate();
    await loadHomeData(forceRefresh: true);
  }

  void toggleCertificateDropdown() {
    _isCertificateDropdownOpen = !_isCertificateDropdownOpen;
    notifyListeners();
  }

  void closeCertificateDropdown() {
    if (_isCertificateDropdownOpen) {
      _isCertificateDropdownOpen = false;
      notifyListeners();
    }
  }

  void selectCertificate(Certificate certificate) {
    _isCertificateDropdownOpen = false;
    _repository.setCurrentCertificate(certificate.id);
    _isInitialized = false;
    loadHomeData(forceRefresh: true);
  }

  void setCurrentMode(int index) {
    if (index >= 0 && index < _studyModes.length) {
      _currentModeIndex = index;
      _currentMode = _studyModes[index];
      notifyListeners();
    }
  }

  double modeProgress(StudyMode mode) {
    final data = _homeData;
    if (data == null) return 0;
    return data.studyModeProgress.progressFor(mode);
  }

  double get currentModeProgress => modeProgress(_currentMode);

  bool get isCurrentModeCompleted => currentModeProgress >= 1.0;

  bool isModeCompleted(StudyMode mode) => modeProgress(mode) >= 1.0;

  /// The mode the bottom CTA should actually launch into. Falls back to the
  /// next incomplete mode in the carousel order when the current one is
  /// already done, so a 100%-complete 개념정리 step naturally points the user
  /// at 기출문제 instead of dead-ending on a "완료" button.
  StudyMode get effectiveMode {
    if (!isModeCompleted(_currentMode)) return _currentMode;
    for (final mode in _studyModes) {
      if (!isModeCompleted(mode)) return mode;
    }
    return _currentMode;
  }

  bool get isAllModesCompleted =>
      _studyModes.every((mode) => isModeCompleted(mode));

  String get startButtonLabel {
    if (isAllModesCompleted) return '오늘 학습 끝!';
    final mode = effectiveMode;
    final progress = modeProgress(mode);
    final verb = progress > 0 ? '이어하기' : '시작하기';
    return '${mode.displayName} $verb';
  }

  bool get canStartCurrentMode {
    final data = _homeData;
    if (data == null) return false;
    if (isAllModesCompleted) return false;

    final mode = effectiveMode;
    switch (mode) {
      case StudyMode.concept:
        return true;
      case StudyMode.practice:
        return data.studyModeProgress.isCompleted(StudyMode.concept);
      case StudyMode.review:
        return data.studyModeProgress.isCompleted(StudyMode.practice);
    }
  }

  void onStartPressed() {
  }

  /// Fires milestone push notifications when /study/today crosses a
  /// threshold the user hasn't seen yet. Three triggers, all idempotent:
  ///   - streak hits 3 days for the first time
  ///   - pass-likelihood crosses 70 going up
  ///   - it's past 21:00 KST and today's plan still has unfinished work
  /// Persists last-seen values in SharedPreferences so the same milestone
  /// doesn't re-fire on every refresh.
  Future<void> _maybeFireMilestones(TodayPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    const kStreakKey = 'milestone_last_streak';
    const kPassKey = 'milestone_last_pass';
    const kLateKey = 'milestone_late_fired_date';

    final lastStreak = prefs.getInt(kStreakKey) ?? 0;
    if (plan.streak >= 3 && lastStreak < 3) {
      await NotificationService().showInstant(
        id: 2001,
        title: '🔥 ${plan.streak}일 연속 학습!',
        body: '오늘도 잊지 않고 따라왔어요. 페이스를 이어가요.',
      );
    }
    await prefs.setInt(kStreakKey, plan.streak);

    final lastPass = prefs.getInt(kPassKey) ?? 0;
    if (plan.passLikelihood >= 70 && lastPass < 70) {
      await NotificationService().showInstant(
        id: 2002,
        title: '✨ 합격 가능성 70% 돌파!',
        body: '${plan.passLikelihood}%까지 올라왔어요. 같은 페이스로 시험일까지!',
      );
    }
    await prefs.setInt(kPassKey, plan.passLikelihood);

    final now = DateTime.now();
    final hasUnfinished =
        plan.tasks.any((t) => t.type != TodayTaskType.mockExam && !t.isComplete);
    if (now.hour >= 21 && hasUnfinished) {
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final lastFired = prefs.getString(kLateKey);
      if (lastFired != todayKey) {
        await NotificationService().showInstant(
          id: 2003,
          title: '🌙 오늘 학습이 남아 있어요',
          body: '내일 시작 부담을 덜기 위해 5분만 보고 갈까요?',
        );
        await prefs.setString(kLateKey, todayKey);
      }
    }
  }
}
