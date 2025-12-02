class Choice {
  final int number;
  final String text;
  final bool isCorrect;

  const Choice({
    required this.number,
    required this.text,
    this.isCorrect = false,
  });
}

class Question {
  final String id;
  final int number;
  final String text;
  final List<Choice> choices;
  final String explanation;
  int? selectedAnswer;
  bool? isCorrect;

  Question({
    required this.id,
    required this.number,
    required this.text,
    required this.choices,
    required this.explanation,
    this.selectedAnswer,
    this.isCorrect,
  });

  int get correctAnswer => choices.indexWhere((c) => c.isCorrect) + 1;
}
