import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/domain/models/home/streak_info.dart';
import 'package:kkeutgong_mobile/domain/models/home/study_mode_progress.dart';
import 'package:kkeutgong_mobile/domain/models/home/subject.dart';

class HomeData {
  final Certificate currentCertificate;
  final int currentDay;
  final double progress;
  final int streakDays;
  final StreakInfo streakInfo;
  final StudyModeProgress studyModeProgress;
  final List<Subject> subjects;
  final List<Certificate> allCertificates;

  HomeData({
    required this.currentCertificate,
    required this.currentDay,
    required this.progress,
    required this.streakDays,
    required this.streakInfo,
    required this.studyModeProgress,
    required this.subjects,
    required this.allCertificates,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      currentCertificate: Certificate.fromJson(json['currentCertificate'] as Map<String, dynamic>),
      currentDay: json['currentDay'] as int,
      progress: (json['progress'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
      streakInfo: StreakInfo.fromJson(json['streakInfo'] as Map<String, dynamic>),
      studyModeProgress: StudyModeProgress.fromJson(json['studyModeProgress'] as Map<String, dynamic>),
      subjects: (json['subjects'] as List).map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList(),
      allCertificates: (json['allCertificates'] as List).map((e) => Certificate.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
