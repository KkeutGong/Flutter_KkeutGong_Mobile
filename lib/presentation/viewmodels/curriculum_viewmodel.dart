import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';

class CurriculumViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final StudyProgressRepository _progressRepository = StudyProgressRepository();

  CurriculumViewModel(HomeRepository? repository) : _repository = repository ?? HomeRepository();

  HomeData? _homeData;
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
    final data = _homeData;
    if (data == null) return 0;
    const targetDay = 11;
    final remaining = targetDay - data.currentDay;
    return remaining > 0 ? remaining : 0;
  }

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
}
