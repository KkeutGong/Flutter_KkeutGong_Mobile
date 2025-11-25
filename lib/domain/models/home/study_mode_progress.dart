import 'package:kkeutgong_mobile/domain/models/home/study_mode.dart';

class StudyModeProgress {
  final double concept;
  final double practice;
  final double review;

  const StudyModeProgress({
    required this.concept,
    required this.practice,
    required this.review,
  });

  factory StudyModeProgress.fromJson(Map<String, dynamic> json) {
    return StudyModeProgress(
      concept: (json['concept'] as num).toDouble(),
      practice: (json['practice'] as num).toDouble(),
      review: (json['review'] as num).toDouble(),
    );
  }

  double progressFor(StudyMode mode) {
    switch (mode) {
      case StudyMode.concept:
        return concept;
      case StudyMode.practice:
        return practice;
      case StudyMode.review:
        return review;
    }
  }

  bool isCompleted(StudyMode mode) => progressFor(mode) >= 1.0;
}
