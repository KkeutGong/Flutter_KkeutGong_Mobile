import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/domain/models/home/streak_info.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;

  HomeViewModel(this._repository);

  HomeData? _homeData;
  HomeData? get homeData => _homeData;

  StreakInfo? get streakInfo => _homeData?.streakInfo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  Future<void> loadHomeData() async {
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
    notifyListeners();
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

  String get startButtonLabel {
    final progress = currentModeProgress;
    final inProgress = progress > 0 && progress < 1;
    return inProgress ? '계속하기' : '시작하기';
  }

  bool get canStartCurrentMode {
    final data = _homeData;
    if (data == null) return false;

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
