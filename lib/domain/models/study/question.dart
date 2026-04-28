class Choice {
  final int number;
  final String text;
  final bool isCorrect;

  const Choice({
    required this.number,
    required this.text,
    this.isCorrect = false,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      number: json['number'] as int,
      text: json['text'] as String,
      isCorrect: (json['isCorrect'] as bool?) ?? false,
    );
  }
}

class Question {
  final String id;
  final int number;
  final String text;
  // Free-form attribution (e.g. '한국사 심화 77회 12번'). Null when content was
  // hand-authored or the source isn't tracked.
  final String? sourceLabel;
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
    this.sourceLabel,
    this.selectedAnswer,
    this.isCorrect,
  });

  int get correctAnswer => choices.indexWhere((c) => c.isCorrect) + 1;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      number: json['number'] as int,
      text: json['text'] as String,
      sourceLabel: json['sourceLabel'] as String?,
      choices: (json['choices'] as List)
          .map((e) => Choice.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanation: (json['explanation'] as String?) ?? '',
      selectedAnswer: json['selectedAnswer'] as int?,
      isCorrect: json['isCorrect'] as bool?,
    );
  }
}
