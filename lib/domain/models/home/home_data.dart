import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/streak_info.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode_progress.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';

class HomeData {
  final Certificate currentCertificate;
  final int currentDay;
  // Server-computed countdown. Null when the user hasn't generated a curriculum
  // yet for this certificate (e.g. brand-new account).
  final DateTime? examDate;
  final int? daysRemaining;
  final double progress;
  final int streakDays;
  final StreakInfo streakInfo;
  final StudyModeProgress studyModeProgress;
  final List<Subject> subjects;
  final List<Certificate> allCertificates;

  HomeData({
    required this.currentCertificate,
    required this.currentDay,
    required this.examDate,
    required this.daysRemaining,
    required this.progress,
    required this.streakDays,
    required this.streakInfo,
    required this.studyModeProgress,
    required this.subjects,
    required this.allCertificates,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final rawExamDate = json['examDate'] as String?;
    final rawDaysRemaining = json['daysRemaining'] as num?;
    return HomeData(
      currentCertificate: Certificate.fromJson(json['currentCertificate'] as Map<String, dynamic>),
      currentDay: json['currentDay'] as int,
      examDate: rawExamDate != null ? DateTime.parse(rawExamDate) : null,
      daysRemaining: rawDaysRemaining?.toInt(),
      progress: (json['progress'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
      streakInfo: StreakInfo.fromJson(json['streakInfo'] as Map<String, dynamic>),
      studyModeProgress: StudyModeProgress.fromJson(json['studyModeProgress'] as Map<String, dynamic>),
      subjects: (json['subjects'] as List).map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList(),
      allCertificates: (json['allCertificates'] as List).map((e) => Certificate.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
