import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/domain/models/study/question.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';

class PracticeStudyViewModel extends ChangeNotifier {
  final String subjectName;
  final StudyProgressRepository _progressRepository = StudyProgressRepository();

  PracticeStudyViewModel({
    required this.subjectName,
  });

  List<Question> _questions = [];
  List<Question> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _showExplanation = false;
  bool get showExplanation => _showExplanation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _error;
  String? get error => _error;

  int get totalQuestions => _questions.length;
  double get progress {
    final answered = _questions.where((q) => q.selectedAnswer != null).length;
    return totalQuestions > 0 ? answered / totalQuestions : 0;
  }
  String get progressText {
    final answered = _questions.where((q) => q.selectedAnswer != null).length;
    return '$answered/$totalQuestions';
  }

  Question? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentIndex] : null;
  bool get hasAnswered => currentQuestion?.selectedAnswer != null;
  bool get hasNext => _currentIndex < _questions.length - 1;
  bool get isCompleted => !hasNext && hasAnswered;

  Future<void> loadQuestions({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _questions = [
        Question(
          id: '1',
          number: 1,
          text: '다음 중 엑셀에서 VLOOKUP 함수의 설명으로 올바른 것은?',
          choices: [
            const Choice(number: 1, text: '수직 방향으로 값을 찾아 반환한다', isCorrect: true),
            const Choice(number: 2, text: '수평 방향으로 값을 찾아 반환한다'),
            const Choice(number: 3, text: '두 값의 평균을 계산한다'),
            const Choice(number: 4, text: '조건에 맞는 값의 개수를 센다'),
          ],
          explanation:
              'VLOOKUP은 Vertical Lookup의 약자로, 세로(수직) 방향으로 데이터를 검색하는 함수입니다.',
        ),
        Question(
          id: '2',
          number: 2,
          text: '다음 중 워드프로세서에서 문단 정렬 방식이 아닌 것은?',
          choices: [
            const Choice(number: 1, text: '왼쪽 정렬'),
            const Choice(number: 2, text: '오른쪽 정렬'),
            const Choice(number: 3, text: '가운데 정렬'),
            const Choice(number: 4, text: '대각선 정렬', isCorrect: true),
          ],
          explanation: '문단 정렬 방식에는 왼쪽, 오른쪽, 가운데, 양쪽 정렬이 있습니다.',
        ),
        Question(
          id: '3',
          number: 3,
          text: 'CPU의 구성 요소가 아닌 것은?',
          choices: [
            const Choice(number: 1, text: '제어장치'),
            const Choice(number: 2, text: '연산장치'),
            const Choice(number: 3, text: '레지스터'),
            const Choice(number: 4, text: '하드디스크', isCorrect: true),
          ],
          explanation: 'CPU는 제어장치, 연산장치(ALU), 레지스터로 구성됩니다.',
        ),
        Question(
          id: '4',
          number: 4,
          text: '다음 중 운영체제의 기능이 아닌 것은?',
          choices: [
            const Choice(number: 1, text: '프로세스 관리'),
            const Choice(number: 2, text: '메모리 관리'),
            const Choice(number: 3, text: '파일 시스템 관리'),
            const Choice(number: 4, text: '문서 작성', isCorrect: true),
          ],
          explanation: '운영체제는 프로세스, 메모리, 파일 시스템, 입출력 장치 등을 관리합니다.',
        ),
        Question(
          id: '5',
          number: 5,
          text: 'OSI 7계층 중 데이터 링크 계층의 역할은?',
          choices: [
            const Choice(
                number: 1, text: '프레임 전송 및 오류 제어', isCorrect: true),
            const Choice(number: 2, text: '라우팅'),
            const Choice(number: 3, text: '세션 관리'),
            const Choice(number: 4, text: '데이터 암호화'),
          ],
          explanation: '데이터 링크 계층은 노드 간 프레임 전송과 오류 제어를 담당합니다.',
        ),
        Question(
          id: '6',
          number: 6,
          text: '다음 중 관계형 데이터베이스의 특징이 아닌 것은?',
          choices: [
            const Choice(number: 1, text: '테이블 형태로 데이터 저장'),
            const Choice(number: 2, text: 'SQL을 사용한 질의'),
            const Choice(number: 3, text: '스키마 정의 필요'),
            const Choice(number: 4, text: '비정형 데이터만 저장 가능', isCorrect: true),
          ],
          explanation: '관계형 데이터베이스는 정형 데이터를 테이블 형태로 저장합니다.',
        ),
        Question(
          id: '7',
          number: 7,
          text: 'HTML에서 하이퍼링크를 만드는 태그는?',
          choices: [
            const Choice(number: 1, text: '<a>', isCorrect: true),
            const Choice(number: 2, text: '<link>'),
            const Choice(number: 3, text: '<href>'),
            const Choice(number: 4, text: '<url>'),
          ],
          explanation: '<a> 태그의 href 속성을 사용하여 하이퍼링크를 만듭니다.',
        ),
        Question(
          id: '8',
          number: 8,
          text: '다음 중 암호화 방식이 아닌 것은?',
          choices: [
            const Choice(number: 1, text: 'AES'),
            const Choice(number: 2, text: 'RSA'),
            const Choice(number: 3, text: 'DES'),
            const Choice(number: 4, text: 'HTTP', isCorrect: true),
          ],
          explanation: 'HTTP는 통신 프로토콜이며, 암호화 방식이 아닙니다.',
        ),
        Question(
          id: '9',
          number: 9,
          text: '다음 중 프로그래밍 언어가 아닌 것은?',
          choices: [
            const Choice(number: 1, text: 'Python'),
            const Choice(number: 2, text: 'Java'),
            const Choice(number: 3, text: 'HTML', isCorrect: true),
            const Choice(number: 4, text: 'C++'),
          ],
          explanation: 'HTML은 마크업 언어이며, 프로그래밍 언어가 아닙니다.',
        ),
        Question(
          id: '10',
          number: 10,
          text: '다음 중 클라우드 서비스 모델이 아닌 것은?',
          choices: [
            const Choice(number: 1, text: 'IaaS'),
            const Choice(number: 2, text: 'PaaS'),
            const Choice(number: 3, text: 'SaaS'),
            const Choice(number: 4, text: 'DaaS', isCorrect: true),
          ],
          explanation: 'IaaS, PaaS, SaaS가 주요 클라우드 서비스 모델입니다.',
        ),
      ];

      // Restore previously selected answers
      final answersMap = await _progressRepository.getPracticeAnswers(subjectName);
      for (final q in _questions) {
        final sel = answersMap[q.id];
        if (sel != null) {
          q.selectedAnswer = sel;
          q.isCorrect = sel == q.correctAnswer;
        }
      }
      // Determine first unanswered index
      final firstUnanswered = _questions.indexWhere((q) => q.selectedAnswer == null);
      if (firstUnanswered >= 0) {
        _currentIndex = firstUnanswered;
      } else {
        _currentIndex = _questions.isNotEmpty ? _questions.length - 1 : 0;
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

  void selectAnswer(int answerNumber) {
    if (_questions.isEmpty || hasAnswered) return;

    final question = _questions[_currentIndex];
    question.selectedAnswer = answerNumber;
    question.isCorrect = answerNumber == question.correctAnswer;
    notifyListeners();
    saveProgress();
  }

  void toggleExplanation() {
    _showExplanation = !_showExplanation;
    notifyListeners();
  }

  void goToNext() {
    if (hasNext) {
      _currentIndex++;
      _showExplanation = false;
      notifyListeners();
      saveProgress();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      _showExplanation = false;
      notifyListeners();
      saveProgress();
    }
  }

  Future<void> saveProgress() async {
    final answeredCount = _questions.where((q) => q.selectedAnswer != null).length;
    await _progressRepository.savePracticeProgress(
      subjectName: subjectName,
      currentIndex: _currentIndex,
      total: totalQuestions,
      answeredCount: answeredCount,
    );
    final answers = <String, int>{};
    for (final q in _questions) {
      if (q.selectedAnswer != null) answers[q.id] = q.selectedAnswer!;
    }
    await _progressRepository.savePracticeAnswers(subjectName: subjectName, answers: answers);
  }

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }
}
