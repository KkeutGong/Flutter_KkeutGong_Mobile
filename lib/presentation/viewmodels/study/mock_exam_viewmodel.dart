import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/study/mock_exam_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/domain/models/study/exam_result.dart';

enum ExamState { ready, inProgress, submitted, submitFailed }

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
      final session = await _repository.startExam(examName: examName);
      _questions = session.questions;
      _remainingSeconds = session.timeLimitMinutes * 60;
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

  Future<void> submitExam() async {
    _timer?.cancel();
    _currentIndex = 0;

    final answers = <String, int>{};
    for (final q in _questions) {
      if (q.selectedAnswer != null) {
        q.isCorrect = q.selectedAnswer == q.correctAnswer;
        answers[q.id] = q.selectedAnswer!;
      } else {
        q.isCorrect = false;
      }
    }

    try {
      _result = await _repository.submitExam(
        examName: examName,
        answers: answers,
        elapsedSeconds: _elapsedSeconds,
      );
      _state = ExamState.submitted;
    } catch (e) {
      // Don't fabricate a pass/fail client-side — the backend formula may
      // differ and showing a wrong result is worse than asking the user to
      // retry. The page renders an error UI when state == submitFailed.
      _error = e.toString();
      _state = ExamState.submitFailed;
    }

    notifyListeners();
  }

  /// Re-attempts submission after a failed network call. Resumes the timer
  /// only if the exam wasn't actually completed (no questions answered) so
  /// the user isn't penalised for the network blip.
  Future<void> retrySubmit() async {
    if (_state != ExamState.submitFailed) return;
    _state = ExamState.inProgress;
    notifyListeners();
    await submitExam();
  }

  void reset() {
    _timer?.cancel();
    _questions = [];
    _state = ExamState.ready;
    _currentIndex = 0;
    _remainingSeconds = 0;
    _elapsedSeconds = 0;
    _result = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    reset();
    super.dispose();
  }
}
