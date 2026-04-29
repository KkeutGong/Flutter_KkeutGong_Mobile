import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';

/// Single unresolved wrong-answer item for the review queue.
class ReviewWrong {
  final String questionId;
  final String subjectId;
  final String subjectName;
  final String text;
  final String? sourceLabel;
  final List<({int number, String text})> choices;
  final String explanation;
  final int wrongCount;
  final DateTime lastWrongAt;
  final int? previousSelected;
  final int? correctAnswer;

  const ReviewWrong({
    required this.questionId,
    required this.subjectId,
    required this.subjectName,
    required this.text,
    required this.sourceLabel,
    required this.choices,
    required this.explanation,
    required this.wrongCount,
    required this.lastWrongAt,
    required this.previousSelected,
    required this.correctAnswer,
  });

  factory ReviewWrong.fromJson(Map<String, dynamic> json) => ReviewWrong(
        questionId: json['questionId'] as String,
        subjectId: json['subjectId'] as String? ?? '',
        subjectName: json['subjectName'] as String? ?? '',
        text: json['text'] as String? ?? '',
        sourceLabel: json['sourceLabel'] as String?,
        choices: ((json['choices'] as List?) ?? const [])
            .map((e) {
              final m = e as Map<String, dynamic>;
              return (
                number: (m['number'] as num?)?.toInt() ?? 0,
                text: m['text'] as String? ?? ''
              );
            })
            .toList(),
        explanation: json['explanation'] as String? ?? '',
        wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
        lastWrongAt: DateTime.tryParse(json['lastWrongAt'] as String? ?? '') ??
            DateTime.now(),
        previousSelected: (json['previousSelected'] as num?)?.toInt(),
        correctAnswer: (json['correctAnswer'] as num?)?.toInt(),
      );
}

class ReviewWrongsRepository {
  static final ReviewWrongsRepository _instance = ReviewWrongsRepository._internal();
  factory ReviewWrongsRepository() => _instance;
  ReviewWrongsRepository._internal();

  final ApiClient _api = ApiClient();
  final Session _session = Session();

  Future<List<ReviewWrong>> getWrongs() async {
    final list = await _api.get('/study/review/wrongs', query: {
      'certificateId': _session.currentCertificateId,
    }) as List;
    return list
        .map((e) => ReviewWrong.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({bool resolved, int? correctAnswer})> resolve(
    String questionId,
    int selectedAnswer,
  ) async {
    final body = await _api.post(
      '/study/review/wrongs/$questionId/resolve',
      body: {'selectedAnswer': selectedAnswer},
    ) as Map<String, dynamic>;
    return (
      resolved: body['resolved'] == true,
      correctAnswer: (body['correctAnswer'] as num?)?.toInt(),
    );
  }
}
