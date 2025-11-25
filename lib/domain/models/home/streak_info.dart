import 'package:kkeutgong_mobile/domain/models/home/streak_day.dart';

class StreakInfo {
  final int currentStreak;
  final int maxStreak;
  final int completedCertificates;
  final int completedLessons;
  final List<StreakDay> recentDays;

  const StreakInfo({
    required this.currentStreak,
    required this.maxStreak,
    required this.completedCertificates,
    required this.completedLessons,
    required this.recentDays,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      currentStreak: json['currentStreak'] as int,
      maxStreak: json['maxStreak'] as int,
      completedCertificates: json['completedCertificates'] as int,
      completedLessons: json['completedLessons'] as int,
      recentDays: (json['recentDays'] as List)
          .map((e) => StreakDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
