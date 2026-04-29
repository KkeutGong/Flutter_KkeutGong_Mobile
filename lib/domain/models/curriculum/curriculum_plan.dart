// Mirrors backend CurriculumService output. Plan v2 adds review/mockExam tasks,
// per-day capacity, sprint phase, and LLM coaching fields. Older v1 plans
// (concept|practice only) still parse — the new fields are optional and the
// UI gracefully falls back when they're missing.

enum CurriculumTaskType { concept, practice, review, mockExam, unknown }

CurriculumTaskType _parseTaskType(String? value) {
  switch (value) {
    case 'concept':
      return CurriculumTaskType.concept;
    case 'practice':
      return CurriculumTaskType.practice;
    case 'review':
      return CurriculumTaskType.review;
    case 'mockExam':
      return CurriculumTaskType.mockExam;
    default:
      return CurriculumTaskType.unknown;
  }
}

enum CurriculumDayPhase { learning, sprint }

CurriculumDayPhase _parsePhase(String? value) {
  return value == 'sprint' ? CurriculumDayPhase.sprint : CurriculumDayPhase.learning;
}

class CurriculumTask {
  final CurriculumTaskType type;
  /// Backend's externalId of the Subject. Null only for `mockExam`.
  final String? subjectId;
  final int count;
  final int? estimatedMinutes;

  const CurriculumTask({
    required this.type,
    required this.subjectId,
    required this.count,
    this.estimatedMinutes,
  });

  factory CurriculumTask.fromJson(Map<String, dynamic> json) => CurriculumTask(
        type: _parseTaskType(json['type'] as String?),
        subjectId: json['subjectId'] as String?,
        count: (json['count'] as num?)?.toInt() ?? 0,
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      );
}

class CurriculumDay {
  final int day;
  final DateTime date;
  final List<CurriculumTask> tasks;
  final int capacityMinutes;
  final int estimatedMinutes;
  final CurriculumDayPhase phase;

  const CurriculumDay({
    required this.day,
    required this.date,
    required this.tasks,
    required this.capacityMinutes,
    required this.estimatedMinutes,
    required this.phase,
  });

  factory CurriculumDay.fromJson(Map<String, dynamic> json) => CurriculumDay(
        day: (json['day'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        tasks: ((json['tasks'] as List?) ?? const [])
            .map((e) => CurriculumTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        capacityMinutes: (json['capacityMinutes'] as num?)?.toInt() ?? 0,
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
        phase: _parsePhase(json['phase'] as String?),
      );
}

class CurriculumPlan {
  final List<CurriculumDay> days;
  final String? studyStyle;
  /// 'algorithm' | 'qwen' | 'placeholder'. UI shows the coaching banner only
  /// when the LLM polish was successful (`qwen`).
  final String? generatedBy;
  /// Korean coaching message from Qwen. Null when LLM was unavailable.
  final String? reasoning;
  /// Subject externalIds the LLM picked for this week's emphasis.
  final List<String> weeklyFocus;
  /// externalId(subject) -> 0..1 weakness score at generation time.
  final Map<String, double> weaknessSnapshot;
  final int? finalSprintStartDay;
  final bool emptyContent;
  final bool overload;

  const CurriculumPlan({
    required this.days,
    this.studyStyle,
    this.generatedBy,
    this.reasoning,
    this.weeklyFocus = const [],
    this.weaknessSnapshot = const {},
    this.finalSprintStartDay,
    this.emptyContent = false,
    this.overload = false,
  });

  factory CurriculumPlan.fromJson(Map<String, dynamic> json) {
    final weakRaw = json['weaknessSnapshot'];
    final weakMap = <String, double>{};
    if (weakRaw is Map) {
      for (final entry in weakRaw.entries) {
        final v = entry.value;
        if (v is num) weakMap[entry.key.toString()] = v.toDouble();
      }
    }
    final focusRaw = json['weeklyFocus'];
    final focus = <String>[];
    if (focusRaw is List) {
      for (final item in focusRaw) {
        if (item is String) focus.add(item);
      }
    }
    return CurriculumPlan(
      days: ((json['days'] as List?) ?? const [])
          .map((e) => CurriculumDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      studyStyle: json['studyStyle'] as String?,
      generatedBy: json['generatedBy'] as String?,
      reasoning: (json['reasoning'] as String?)?.trim().isEmpty == true
          ? null
          : json['reasoning'] as String?,
      weeklyFocus: focus,
      weaknessSnapshot: weakMap,
      finalSprintStartDay: (json['finalSprintStartDay'] as num?)?.toInt(),
      emptyContent: json['emptyContent'] == true,
      overload: json['overload'] == true,
    );
  }
}

class MyCurriculum {
  final String id;
  final String certificateId;
  final DateTime examDate;
  final int hoursPerWeek;
  final CurriculumPlan plan;
  /// 0..1 — server-computed fraction of today's planned tasks the user has
  /// already done since midnight. The UI uses this directly so a single user
  /// completing 3 of 3 today shows 100%, regardless of overall subject %.
  final double todayProgress;
  final int todayCompleted;
  final int todayPlanned;

  const MyCurriculum({
    required this.id,
    required this.certificateId,
    required this.examDate,
    required this.hoursPerWeek,
    required this.plan,
    required this.todayProgress,
    required this.todayCompleted,
    required this.todayPlanned,
  });

  factory MyCurriculum.fromJson(Map<String, dynamic> json) => MyCurriculum(
        id: json['id'] as String,
        certificateId: json['certificateId'] as String,
        examDate: DateTime.parse(json['examDate'] as String),
        hoursPerWeek: (json['hoursPerWeek'] as num).toInt(),
        plan: CurriculumPlan.fromJson(json['plan'] as Map<String, dynamic>),
        todayProgress: (json['todayProgress'] as num?)?.toDouble() ?? 0,
        todayCompleted: (json['todayCompleted'] as num?)?.toInt() ?? 0,
        todayPlanned: (json['todayPlanned'] as num?)?.toInt() ?? 0,
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
