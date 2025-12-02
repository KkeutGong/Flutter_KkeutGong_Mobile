import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/streak_info.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;

  HomeViewModel(HomeRepository? repository) : _repository = repository ?? HomeRepository();

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

  String get startButtonLabel {
    final progress = currentModeProgress;
    if (progress >= 1) return '완료';
    if (progress > 0) return '계속하기';
    return '시작하기';
  }

  bool get canStartCurrentMode {
    final data = _homeData;
    if (data == null) return false;

    // 이미 완료된 모드는 시작 불가
    if (isCurrentModeCompleted) return false;

    switch (_currentMode) {
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
}
