class StudyCard {
  final String id;
  final String question;
  final String answer;
  bool isFavorite;
  bool isKnown;

  StudyCard({
    required this.id,
    required this.question,
    required this.answer,
    this.isFavorite = false,
    this.isKnown = false,
  });
}
