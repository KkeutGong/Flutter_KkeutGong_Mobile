import 'package:kkeutgong_mobile/core/api/api_client.dart';

class QuestionExplanation {
  final String text;
  final String source; // 'qwen' | 'cache' | 'fallback'
  final int? correctAnswer;
  final bool isCorrect;

  const QuestionExplanation({
    required this.text,
    required this.source,
    required this.correctAnswer,
    required this.isCorrect,
  });

  factory QuestionExplanation.fromJson(Map<String, dynamic> json) =>
      QuestionExplanation(
        text: (json['text'] as String?) ?? '',
        source: (json['source'] as String?) ?? 'fallback',
        correctAnswer: (json['correctAnswer'] as num?)?.toInt(),
        isCorrect: json['isCorrect'] == true,
      );
}

/// Thin wrapper around POST /api/study/explain — server caches per
/// (questionId, selectedAnswer) so we can hit it on every reveal without
/// fear. Returns the static fallback when Qwen is unreachable.
class ExplainRepository {
  static final ExplainRepository _instance = ExplainRepository._internal();
  factory ExplainRepository() => _instance;
  ExplainRepository._internal();

  final ApiClient _api = ApiClient();

  Future<QuestionExplanation> explain(
    String questionId,
    int selectedAnswer,
  ) async {
    final body = await _api.post(
      '/study/explain/$questionId',
      body: {'selectedAnswer': selectedAnswer},
    );
    return QuestionExplanation.fromJson(body as Map<String, dynamic>);
  }
}
