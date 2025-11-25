import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';

class CurriculumViewModel extends ChangeNotifier {
  final HomeRepository _repository;

  CurriculumViewModel(this._repository);

  HomeData? _homeData;
  bool _isLoading = false;
  String? _error;

  HomeData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _repository.getHomeData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
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
    return data.studyModeProgress.progressFor(mode);
  }

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
    load();
  }
}
