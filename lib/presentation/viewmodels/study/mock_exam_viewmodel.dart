import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/study/mock_exam_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/domain/models/study/exam_result.dart';

enum ExamState { ready, inProgress, submitted }

class MockExamViewModel extends ChangeNotifier {
  final MockExamRepository _repository;
  final String examName;
  final int timeLimitMinutes;

  MockExamViewModel({
    required this.examName,
    this.timeLimitMinutes = 150,
    MockExamRepository? repository,
  }) : _repository = repository ?? MockExamRepository();

  List<Question> _questions = [];
  List<Question> get questions => _questions;

  ExamState _state = ExamState.ready;
  ExamState get state => _state;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Timer? _timer;
  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  ExamResult? _result;
  ExamResult? get result => _result;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _error;
  String? get error => _error;

  int get totalQuestions => _questions.length;
  Question? get currentQuestion => _questions.isNotEmpty ? _questions[_currentIndex] : null;
  bool get allAnswered => _questions.every((q) => q.selectedAnswer != null);
  int get unansweredCount => _questions.where((q) => q.selectedAnswer == null).length;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    return '$minutes분';
  }

  Future<void> loadQuestions({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _questions = await _repository.getQuestions(examName, forceRefresh: forceRefresh);
      _remainingSeconds = timeLimitMinutes * 60;
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void startExam() {
    _state = ExamState.inProgress;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _elapsedSeconds++;
        notifyListeners();
      } else {
        submitExam();
      }
    });
  }

  void selectAnswer(int answerNumber) {
    if (_questions.isEmpty) return;

    _questions[_currentIndex].selectedAnswer = answerNumber;
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToNext() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void goToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void submitExam() {
    _timer?.cancel();
    _currentIndex = 0;

    for (final question in _questions) {
      if (question.selectedAnswer != null) {
        question.isCorrect = question.selectedAnswer == question.correctAnswer;
      } else {
        question.isCorrect = false;
      }
    }

    final correctCount = _questions.where((q) => q.isCorrect == true).length;
    final subjectScores = <String, SubjectScore>{
      '전기이론': SubjectScore(
        name: '전기이론',
        totalQuestions: _questions.length,
        correctCount: correctCount,
      ),
    };

    _result = ExamResult(
      totalQuestions: _questions.length,
      correctCount: correctCount,
      elapsedTime: Duration(seconds: _elapsedSeconds),
      isPassed: correctCount >= (_questions.length * 0.6).round(),
      subjectScores: subjectScores,
    );

    _state = ExamState.submitted;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _questions = [];
    _state = ExamState.ready;
    _currentIndex = 0;
    _remainingSeconds = 0;
    _elapsedSeconds = 0;
    _result = null;
    _isLoading = false;
    _isInitialized = false;
    _error = null;
    _repository.invalidateCache(examName);
  }

  @override
  void dispose() {
    _timer?.cancel();
    reset();
    super.dispose();
  }
}
