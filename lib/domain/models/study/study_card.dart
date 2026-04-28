class StudyCard {
  final String id;
  final String question;
  final String answer;
  // Free-form attribution (e.g. '한국사 심화 77회 1번'). Null when content was
  // hand-authored or the source isn't tracked yet — UI hides the badge then.
  final String? sourceLabel;
  bool isFavorite;
  bool isKnown;

  StudyCard({
    required this.id,
    required this.question,
    required this.answer,
    this.sourceLabel,
    this.isFavorite = false,
    this.isKnown = false,
  });

  factory StudyCard.fromJson(Map<String, dynamic> json) {
    return StudyCard(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      sourceLabel: json['sourceLabel'] as String?,
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      isKnown: (json['isKnown'] as bool?) ?? false,
    );
  }
}
