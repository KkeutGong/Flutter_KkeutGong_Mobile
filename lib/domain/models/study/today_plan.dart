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

/// AI coach line shown above today's plan. `source = 'fallback'` means
/// the deterministic message kicked in (Qwen offline or no plan yet); the
/// home banner can use that to show a subtle "기본 가이드" badge.
class CoachMessage {
  final String text;
  final String source; // 'qwen' | 'fallback'

  const CoachMessage({required this.text, required this.source});

  bool get isFallback => source == 'fallback';

  factory CoachMessage.fromJson(Map<String, dynamic> json) => CoachMessage(
        text: (json['text'] as String?) ?? '',
        source: (json['source'] as String?) ?? 'fallback',
      );

  static const empty = CoachMessage(text: '', source: 'fallback');
}

/// Diff summary of how the plan changed since the last recompute. Drives
/// the "AI가 데이터베이스 +20% 늘렸어요" toast on the home tab.
class PlanAdaptation {
  final bool changed;
  final String summary;

  const PlanAdaptation({required this.changed, required this.summary});

  factory PlanAdaptation.fromJson(Map<String, dynamic> json) => PlanAdaptation(
        changed: json['changed'] == true,
        summary: (json['summary'] as String?) ?? '',
      );
}

class TodayPlan {
  final List<TodayTask> tasks;
  /// Adaptive ordering — same set as `tasks` but sorted (mock first, then
  /// weakest subject, then concept→practice→review). The home hero renders
  /// this directly so the user always sees the AI-recommended next step.
  final List<TodayTask> orderedTasks;
  final bool mockExamPlanned;
  final int softCapAvailable;
  final int passLikelihood;
  final String passLikelihoodReason;
  final CoachMessage coachMessage;
  final PlanAdaptation? adaptation;
  final int? dDay;

  const TodayPlan({
    required this.tasks,
    required this.orderedTasks,
    required this.mockExamPlanned,
    required this.softCapAvailable,
    required this.passLikelihood,
    required this.passLikelihoodReason,
    required this.coachMessage,
    required this.adaptation,
    required this.dDay,
  });

  bool get isEmpty => tasks.isEmpty;
  bool get isAllDone =>
      tasks.isNotEmpty && tasks.every((t) => t.isComplete);

  factory TodayPlan.fromJson(Map<String, dynamic> json) {
    final tasks = ((json['tasks'] as List?) ?? const [])
        .map((e) => TodayTask.fromJson(e as Map<String, dynamic>))
        .toList();
    final ordered = ((json['todayTaskOrder'] as List?) ?? const [])
        .map((e) => TodayTask.fromJson(e as Map<String, dynamic>))
        .toList();
    return TodayPlan(
      tasks: tasks,
      orderedTasks: ordered.isNotEmpty ? ordered : tasks,
      mockExamPlanned: json['mockExamPlanned'] == true,
      softCapAvailable: (json['softCapAvailable'] as num?)?.toInt() ?? 0,
      passLikelihood: (json['passLikelihood'] as num?)?.toInt() ?? 0,
      passLikelihoodReason: (json['passLikelihoodReason'] as String?) ?? '',
      coachMessage: json['coachMessage'] is Map<String, dynamic>
          ? CoachMessage.fromJson(json['coachMessage'] as Map<String, dynamic>)
          : CoachMessage.empty,
      adaptation: json['adaptation'] is Map<String, dynamic>
          ? PlanAdaptation.fromJson(json['adaptation'] as Map<String, dynamic>)
          : null,
      dDay: (json['dDay'] as num?)?.toInt(),
    );
  }

  static TodayPlan empty() => const TodayPlan(
        tasks: [],
        orderedTasks: [],
        mockExamPlanned: false,
        softCapAvailable: 0,
        passLikelihood: 0,
        passLikelihoodReason: '',
        coachMessage: CoachMessage.empty,
        adaptation: null,
        dDay: null,
      );
}
