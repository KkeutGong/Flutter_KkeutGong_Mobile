enum StudyMode {
  concept,
  practice,
  review;

  String get displayName {
    switch (this) {
      case StudyMode.concept:
        return '개념정리';
      case StudyMode.practice:
        return '기출문제';
      case StudyMode.review:
        return '약점복습';
    }
  }

  String get iconName {
    switch (this) {
      case StudyMode.concept:
        return 'draw';
      case StudyMode.practice:
        return 'edit_note';
      case StudyMode.review:
        return 'quiz';
    }
  }
}
