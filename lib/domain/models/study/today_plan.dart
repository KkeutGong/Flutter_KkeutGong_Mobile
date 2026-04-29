/// Mirrors the GET /study/today response. Drives the home tab's per-subject
/// task launchers and the curriculum tab's daily roadmap. The backend
/// computes planned/completed/remaining against today's date so the client
/// just renders — no recomputation on the device.

enum TodayTaskType { concept, practice, review, mockExam, unknown }

TodayTaskType _parseType(String? value) {
  switch (value) {
    case 'concept':
      return TodayTaskType.concept;
    case 'practice':
      return TodayTaskType.practice;
    case 'review':
      return TodayTaskType.review;
    case 'mockExam':
      return TodayTaskType.mockExam;
    default:
      return TodayTaskType.unknown;
  }
}

class TodayTask {
  final TodayTaskType type;
  final String? subjectId;
  final int planned;
  final int completed;
  final int remaining;
  final int? estimatedMinutes;

  const TodayTask({
    required this.type,
    required this.subjectId,
    required this.planned,
    required this.completed,
    required this.remaining,
    this.estimatedMinutes,
  });

  bool get isComplete => remaining == 0;

  factory TodayTask.fromJson(Map<String, dynamic> json) => TodayTask(
        type: _parseType(json['type'] as String?),
        subjectId: json['subjectId'] as String?,
        planned: (json['planned'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        remaining: (json['remaining'] as num?)?.toInt() ?? 0,
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      );
}

class TodayPlan {
  final List<TodayTask> tasks;
  final bool mockExamPlanned;
  final int softCapAvailable;

  const TodayPlan({
    required this.tasks,
    required this.mockExamPlanned,
    required this.softCapAvailable,
  });

  bool get isEmpty => tasks.isEmpty;
  bool get isAllDone =>
      tasks.isNotEmpty && tasks.every((t) => t.isComplete);

  factory TodayPlan.fromJson(Map<String, dynamic> json) => TodayPlan(
        tasks: ((json['tasks'] as List?) ?? const [])
            .map((e) => TodayTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        mockExamPlanned: json['mockExamPlanned'] == true,
        softCapAvailable: (json['softCapAvailable'] as num?)?.toInt() ?? 0,
      );

  static TodayPlan empty() =>
      const TodayPlan(tasks: [], mockExamPlanned: false, softCapAvailable: 0);
}
