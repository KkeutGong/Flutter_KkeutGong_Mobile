import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/curriculum/curriculum_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/curriculum/curriculum_plan.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';

class CurriculumViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final CurriculumRepository _curriculumRepo = CurriculumRepository();
  final StudyProgressRepository _progressRepository = StudyProgressRepository();

  CurriculumViewModel(HomeRepository? repository) : _repository = repository ?? HomeRepository();

  HomeData? _homeData;
  MyCurriculum? _myCurriculum;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  HomeData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _repository.getHomeData(forceRefresh: forceRefresh);
      final subjectsList = _homeData?.subjects ?? [];
      for (final s in subjectsList) {
        final p = await _progressRepository.getPracticePercent(s.name);
        final c = await _progressRepository.getConceptPercent(s.name);
        _practicePercentBySubject[s.name] = p;
        _conceptPercentBySubject[s.name] = c;
      }
      // Fetch the daily plan separately. A null/error response just hides the
      // "오늘의 학습" section — the rest of the page still renders.
      final certId = _homeData?.currentCertificate.id;
      if (certId != null) {
        try {
          _myCurriculum = await _curriculumRepo.getMyCurriculum(certId);
        } catch (_) {
          _myCurriculum = null;
        }
      } else {
        _myCurriculum = null;
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
    _practicePercentBySubject.clear();
    _conceptPercentBySubject.clear();
    _isInitialized = false;
    await load(forceRefresh: true);
  }

  List<Subject> get subjects {
    final data = _homeData;
    if (data == null) return [];
    final ongoing = data.subjects.where((subject) => !subject.isCompleted).toList();
    final completed = data.subjects.where((subject) => subject.isCompleted).toList();
    return [...ongoing, ...completed];
  }

  Subject? get activeSubject {
    final data = _homeData;
    if (data == null || data.subjects.isEmpty) return null;
    return data.subjects.firstWhere(
      (subject) => !subject.isCompleted,
      orElse: () => data.subjects.first,
    );
  }

  List<StudyMode> get studyModes => StudyMode.values;

  double subjectModeProgress(Subject subject, StudyMode mode) {
    if (subject.isCompleted) return 1;
    final active = activeSubject;
    if (active == null) return 0;
    if (subject.id != active.id) return 0;
    final data = _homeData;
    if (data == null) return 0;
    switch (mode) {
      case StudyMode.concept:
        final persistedConcept = _conceptPercentBySubject[subject.name];
        if (persistedConcept != null && persistedConcept > 0) return persistedConcept;
        return data.studyModeProgress.progressFor(mode);
      case StudyMode.practice:
        final persisted = _practicePercentBySubject[subject.name];
        if (persisted != null && persisted > 0) return persisted;
        return data.studyModeProgress.progressFor(mode);
      case StudyMode.review:
        return data.studyModeProgress.progressFor(mode);
    }
  }

  final Map<String, double> _practicePercentBySubject = {};
  final Map<String, double> _conceptPercentBySubject = {};

  bool isModeUnlocked(Subject subject, StudyMode mode) {
    if (subject.isCompleted) return true;
    final active = activeSubject;
    if (active == null) return false;
    if (subject.id != active.id) return false;
    switch (mode) {
      case StudyMode.concept:
        return true;
      case StudyMode.practice:
        return subjectModeProgress(subject, StudyMode.concept) >= 1;
      case StudyMode.review:
        return subjectModeProgress(subject, StudyMode.practice) >= 1;
    }
  }

  bool isUnitLocked(Subject subject, StudyMode mode) => !isModeUnlocked(subject, mode);

  String unitButtonLabel(Subject subject, StudyMode mode) {
    final progress = subjectModeProgress(subject, mode);
    if (progress >= 1) return '완료';
    if (progress > 0) return '계속하기';
    return '시작하기';
  }

  bool unitButtonEnabled(Subject subject, StudyMode mode) {
    final progress = subjectModeProgress(subject, mode);
    if (progress >= 1) return false;
    return isModeUnlocked(subject, mode);
  }

  double progressPercentage(Subject subject, StudyMode mode) {
    final progress = subjectModeProgress(subject, mode);
    if (progress <= 0) return 0;
    if (progress >= 1) return 1;
    return progress;
  }

  int get examDDay {
    // The backend computes daysRemaining from the user's curriculum.examDate
    // every request, so the countdown stays accurate even if the device clock
    // has drifted. Null means the user hasn't generated a curriculum yet.
    return _homeData?.daysRemaining ?? 0;
  }

  bool get hasExamDate => _homeData?.examDate != null;

  double get progress => _homeData?.progress ?? 0;

  bool get isExamReady {
    final data = _homeData;
    if (data == null || data.subjects.isEmpty) return false;
    return data.subjects.every((subject) => subject.isCompleted);
  }

  void selectCertificate(String certificateId) {
    _repository.setCurrentCertificate(certificateId);
    _isInitialized = false;
    load(forceRefresh: true);
  }

  // ── Today's plan ───────────────────────────────────────────────────────────
  // Drives the "오늘의 학습" mini-section. Null when:
  //  - the user hasn't generated a curriculum yet, or
  //  - today is past the last planned day (ran out of plan).

  MyCurriculum? get myCurriculum => _myCurriculum;

  CurriculumDay? get todayPlan {
    final c = _myCurriculum;
    if (c == null) return null;
    return c.dayFor(DateTime.now());
  }

  /// Aggregated counts for today, broken down by task type. Mock-exam count
  /// is shown separately because it's the only task type that's per-cert
  /// rather than per-subject (and the UI label differs).
  ({int conceptCount, int practiceCount, int reviewCount, int mockExamCount})
      get todayTaskCounts {
    final day = todayPlan;
    if (day == null) {
      return (conceptCount: 0, practiceCount: 0, reviewCount: 0, mockExamCount: 0);
    }
    int concept = 0;
    int practice = 0;
    int review = 0;
    int mock = 0;
    for (final t in day.tasks) {
      switch (t.type) {
        case CurriculumTaskType.concept:
          concept += t.count;
          break;
        case CurriculumTaskType.practice:
          practice += t.count;
          break;
        case CurriculumTaskType.review:
          review += t.count;
          break;
        case CurriculumTaskType.mockExam:
          mock += t.count;
          break;
        case CurriculumTaskType.unknown:
          break;
      }
    }
    return (conceptCount: concept, practiceCount: practice, reviewCount: review, mockExamCount: mock);
  }

  /// 0..1 — server-computed fraction of today's plan the user has done since
  /// midnight. Backend counts ConceptKnown/PracticeAnswer/MockExam rows
  /// created today against the planned task counts. Honest progress instead
  /// of subject-percent average.
  double get todayProgress => _myCurriculum?.todayProgress ?? 0;

  int get todayCompleted => _myCurriculum?.todayCompleted ?? 0;
  int get todayPlanned => _myCurriculum?.todayPlanned ?? 0;

  /// Coaching message Qwen produced for the current plan; null when the LLM
  /// was unreachable or this plan was generated by the algorithm alone.
  String? get coachingMessage => _myCurriculum?.plan.reasoning;

  /// True when today's day is in the final sprint window (mock + review).
  /// UI uses this to swap colors / show a "마무리 sprint" badge.
  bool get isSprintToday => todayPlan?.phase == CurriculumDayPhase.sprint;

  /// True when the algorithm flagged that the user's hoursPerWeek can't fit
  /// all remaining content before the exam. UI surfaces a warning.
  bool get planOverload => _myCurriculum?.plan.overload ?? false;

  /// True when the cert has no content yet so today's plan would be empty.
  /// UI shows "콘텐츠 준비중" placeholder instead of the daily card.
  bool get planEmptyContent => _myCurriculum?.plan.emptyContent ?? false;
}
