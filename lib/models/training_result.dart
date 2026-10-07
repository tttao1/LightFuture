import 'game_catalog.dart';

class TrainingResult {
  TrainingResult({
    required this.game,
    required this.level,
    required this.score,
    required this.correct,
    required this.attempts,
    required this.seconds,
    required this.completed,
    Map<String, String> metrics = const {},
    DateTime? date,
    this.rulesVersion = 1,
  }) : metrics = Map.unmodifiable(metrics),
       date = date ?? DateTime.now();

  final GameId game;
  final int level, score, correct, attempts, rulesVersion;
  final double seconds;
  final bool completed;
  final Map<String, String> metrics;
  final DateTime date;
  double get accuracy =>
      attempts == 0 ? 0 : (correct / attempts).clamp(0.0, 1.0);
  String get key => '${game.name}:$level:$rulesVersion';
  String get evaluation => !completed
      ? '时间到了，下一次继续挑战。'
      : accuracy >= 0.95
      ? '表现优秀，保持这份专注！'
      : accuracy >= 0.7
      ? '训练完成，正在找到更好的节奏。'
      : '完成了一次挑战，再练一次试试。';

  bool betterThan(TrainingResult? other) {
    if (!completed || correct == 0) return false;
    if (other == null) return true;
    if (game == GameId.schulte) {
      return seconds < other.seconds ||
          (seconds == other.seconds && accuracy > other.accuracy);
    }
    if (game == GameId.reactionSpeed) {
      if (accuracy != other.accuracy) return accuracy > other.accuracy;
      final currentMs =
          double.tryParse(metrics['平均反应毫秒'] ?? '') ?? double.infinity;
      final oldMs =
          double.tryParse(other.metrics['平均反应毫秒'] ?? '') ?? double.infinity;
      return currentMs < oldMs;
    }
    return score > other.score ||
        (score == other.score && seconds < other.seconds);
  }

  Map<String, Object?> toJson() => {
    'game': game.name,
    'level': level,
    'score': score,
    'correct': correct,
    'attempts': attempts,
    'seconds': seconds,
    'completed': completed,
    'metrics': metrics,
    'date': date.toIso8601String(),
    'rulesVersion': rulesVersion,
  };

  factory TrainingResult.fromJson(Map<String, dynamic> json) {
    final result = TrainingResult(
      game: GameId.values.byName(json['game'] as String),
      level: json['level'] as int,
      score: json['score'] as int,
      correct: json['correct'] as int,
      attempts: json['attempts'] as int,
      seconds: (json['seconds'] as num).toDouble(),
      completed: json['completed'] as bool,
      metrics: Map<String, String>.from(json['metrics'] as Map),
      date: DateTime.parse(json['date'] as String),
      rulesVersion: json['rulesVersion'] as int? ?? 1,
    );
    if (result.level < 1 ||
        result.level > 10 ||
        result.score < 0 ||
        result.score > 1000 ||
        result.correct < 0 ||
        result.attempts < result.correct ||
        !result.seconds.isFinite ||
        result.seconds < 0) {
      throw const FormatException('Invalid local training result');
    }
    return result;
  }
}
