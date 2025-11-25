class StreakDay {
  final DateTime date;
  final bool isCompleted;

  const StreakDay({
    required this.date,
    required this.isCompleted,
  });

  factory StreakDay.fromJson(Map<String, dynamic> json) {
    return StreakDay(
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}
