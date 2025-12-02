class ExamResult {
  final int totalQuestions;
  final int correctCount;
  final Duration elapsedTime;
  final bool isPassed;
  final Map<String, SubjectScore> subjectScores;

  const ExamResult({
    required this.totalQuestions,
    required this.correctCount,
    required this.elapsedTime,
    required this.isPassed,
    required this.subjectScores,
  });

  double get accuracy => totalQuestions > 0 ? correctCount / totalQuestions : 0;
}

class SubjectScore {
  final String name;
  final int totalQuestions;
  final int correctCount;

  const SubjectScore({
    required this.name,
    required this.totalQuestions,
    required this.correctCount,
  });

  double get accuracy => totalQuestions > 0 ? correctCount / totalQuestions : 0;
}
