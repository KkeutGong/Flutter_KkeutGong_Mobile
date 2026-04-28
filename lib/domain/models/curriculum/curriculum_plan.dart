// Mirrors backend CurriculumService.buildPlan output.
//
// `MyCurriculum` is the response from GET /curricula/me. The `plan` JSON has
// the daily breakdown the onboarding generator produced, so the UI can show
// "오늘 해야 할 분량" without recomputing locally.

class CurriculumTask {
  final String type; // 'concept' | 'practice'
  final String subjectId; // externalId of Subject
  final int count;

  const CurriculumTask({
    required this.type,
    required this.subjectId,
    required this.count,
  });

  factory CurriculumTask.fromJson(Map<String, dynamic> json) => CurriculumTask(
        type: json['type'] as String,
        subjectId: json['subjectId'] as String,
        count: (json['count'] as num).toInt(),
      );
}

class CurriculumDay {
  final int day;
  final DateTime date;
  final List<CurriculumTask> tasks;

  const CurriculumDay({
    required this.day,
    required this.date,
    required this.tasks,
  });

  factory CurriculumDay.fromJson(Map<String, dynamic> json) => CurriculumDay(
        day: (json['day'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        tasks: ((json['tasks'] as List?) ?? const [])
            .map((e) => CurriculumTask.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CurriculumPlan {
  final List<CurriculumDay> days;
  final String? studyStyle;

  const CurriculumPlan({required this.days, this.studyStyle});

  factory CurriculumPlan.fromJson(Map<String, dynamic> json) => CurriculumPlan(
        days: ((json['days'] as List?) ?? const [])
            .map((e) => CurriculumDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        studyStyle: json['studyStyle'] as String?,
      );
}

class MyCurriculum {
  final String id;
  final String certificateId;
  final DateTime examDate;
  final int hoursPerWeek;
  final CurriculumPlan plan;

  const MyCurriculum({
    required this.id,
    required this.certificateId,
    required this.examDate,
    required this.hoursPerWeek,
    required this.plan,
  });

  factory MyCurriculum.fromJson(Map<String, dynamic> json) => MyCurriculum(
        id: json['id'] as String,
        certificateId: json['certificateId'] as String,
        examDate: DateTime.parse(json['examDate'] as String),
        hoursPerWeek: (json['hoursPerWeek'] as num).toInt(),
        plan: CurriculumPlan.fromJson(json['plan'] as Map<String, dynamic>),
      );

  CurriculumDay? dayFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final d in plan.days) {
      final dKey = DateTime(d.date.year, d.date.month, d.date.day);
      if (dKey == key) return d;
    }
    return null;
  }
}
