import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum ReactionPhase {
  idle,
  countdown,
  waiting,
  ready,
  feedback,
  paused,
  finished,
}

enum AttemptOutcome { success, falseStart, timeout }

@immutable
class ReactionAttempt {
  const ReactionAttempt(this.outcome, {this.milliseconds});

  final AttemptOutcome outcome;
  final int? milliseconds;
}

@immutable
class ReactionSummary {
  ReactionSummary({
    required this.level,
    required List<ReactionAttempt> attempts,
  }) : attempts = List.unmodifiable(attempts);

  final int level;
  final List<ReactionAttempt> attempts;

  int get successes =>
      attempts.where((a) => a.outcome == AttemptOutcome.success).length;
  int get falseStarts =>
      attempts.where((a) => a.outcome == AttemptOutcome.falseStart).length;
  int get timeouts =>
      attempts.where((a) => a.outcome == AttemptOutcome.timeout).length;
  double get accuracy => attempts.isEmpty ? 0 : successes / attempts.length;

  double? get averageMilliseconds {
    final values = attempts
        .where((a) => a.outcome == AttemptOutcome.success)
        .map((a) => a.milliseconds!);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get responseLimit => ReactionController.responseLimitFor(level);

  int get score {
    final average = averageMilliseconds;
    if (average == null) return 0;
    final speed = (1 - average / responseLimit).clamp(0.0, 1.0);
    return (accuracy * (700 + 300 * speed)).round();
  }

  bool isBetterThan(ReactionSummary? other) {
    if (successes == 0) return false;
    if (other == null) return true;
    if (accuracy != other.accuracy) return accuracy > other.accuracy;
    return averageMilliseconds! <
        (other.averageMilliseconds ?? double.infinity);
  }

  String get comment {
    if (successes == 0) return '等绿色信号出现后再点击，慢慢来。';
    if (falseStarts > 0) return '已经找到节奏了，下次试着避免抢跑。';
    if (accuracy == 1) return '五轮全部成功，专注得很棒！';
    return '训练完成，再试一次挑战自己的成绩。';
  }
}

/// Owns trial state and timers. A UI must acknowledge the green frame before
/// response timing starts, so time spent waiting for a frame is not scored.
class ReactionController extends ChangeNotifier {
  ReactionController({
    required this.level,
    int Function()? nowMicros,
    Duration Function()? waitingDuration,
  }) : assert(level >= 1 && level <= 10),
       _nowMicros = nowMicros,
       _waitingDuration = waitingDuration;

  static const roundCount = 5;
  static const feedbackDuration = Duration(milliseconds: 1100);

  static int responseLimitFor(int level) =>
      const [1500, 1400, 1300, 1150, 1000, 950, 900, 850, 800, 700][level - 1];

  final int level;
  final int Function()? _nowMicros;
  final Duration Function()? _waitingDuration;
  final Stopwatch _clock = Stopwatch()..start();
  final Random _random = Random();
  final List<ReactionAttempt> _attempts = [];
  Timer? _timer;
  int? _signalAt;
  bool _disposed = false;
  ReactionPhase _phase = ReactionPhase.idle;
  int _countdown = 3;
  int _signalToken = 0;

  ReactionPhase get phase => _phase;
  int get countdown => _countdown;
  int get signalToken => _signalToken;
  int get responseLimit => responseLimitFor(level);
  int get currentRound => _phase == ReactionPhase.feedback
      ? _attempts.length
      : min(_attempts.length + 1, roundCount);
  List<ReactionAttempt> get attempts => List.unmodifiable(_attempts);
  ReactionAttempt? get lastAttempt => _attempts.isEmpty ? null : _attempts.last;
  ReactionSummary get summary =>
      ReactionSummary(level: level, attempts: _attempts);

  int get _now => _nowMicros?.call() ?? _clock.elapsedMicroseconds;

  void start() {
    if (_disposed) return;
    _timer?.cancel();
    _attempts.clear();
    _signalAt = null;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _signalAt = null;
    _countdown = 3;
    _phase = ReactionPhase.countdown;
    _notify();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        _countdown--;
        _notify();
      } else {
        timer.cancel();
        _beginWaiting();
      }
    });
  }

  void _beginWaiting() {
    _signalAt = null;
    _phase = ReactionPhase.waiting;
    _notify();
    final duration =
        _waitingDuration?.call() ??
        Duration(milliseconds: 1500 + _random.nextInt(3001));
    _timer = Timer(duration, () {
      _phase = ReactionPhase.ready;
      _signalToken++;
      _notify();
    });
  }

  void signalFramePresented(int token) {
    if (_disposed ||
        _phase != ReactionPhase.ready ||
        _signalAt != null ||
        token != _signalToken) {
      return;
    }
    _signalAt = _now;
    _timer = Timer(Duration(milliseconds: responseLimit), () {
      _settle(const ReactionAttempt(AttemptOutcome.timeout));
    });
  }

  void tap() {
    if (_disposed) return;
    if (_phase == ReactionPhase.waiting) {
      _settle(const ReactionAttempt(AttemptOutcome.falseStart));
      return;
    }
    if (_phase != ReactionPhase.ready || _signalAt == null) return;
    final elapsedMicros = max(0, _now - _signalAt!);
    if (elapsedMicros >= responseLimit * 1000) {
      _settle(const ReactionAttempt(AttemptOutcome.timeout));
    } else {
      _settle(
        ReactionAttempt(
          AttemptOutcome.success,
          milliseconds: max(1, (elapsedMicros / 1000).round()),
        ),
      );
    }
  }

  void _settle(ReactionAttempt attempt) {
    if (_disposed ||
        (_phase != ReactionPhase.waiting && _phase != ReactionPhase.ready)) {
      return;
    }
    _timer?.cancel();
    _signalAt = null;
    _attempts.add(attempt);
    _phase = ReactionPhase.feedback;
    _notify();
    _timer = Timer(feedbackDuration, () {
      if (_attempts.length == roundCount) {
        _phase = ReactionPhase.finished;
        _notify();
      } else {
        _beginWaiting();
      }
    });
  }

  void pause() {
    if (_disposed ||
        _phase == ReactionPhase.idle ||
        _phase == ReactionPhase.paused ||
        _phase == ReactionPhase.finished) {
      return;
    }
    _timer?.cancel();
    _signalAt = null;
    _phase = ReactionPhase.paused;
    _notify();
  }

  void resume() {
    if (_disposed || _phase != ReactionPhase.paused) return;
    if (_attempts.length == roundCount) {
      _phase = ReactionPhase.finished;
      _notify();
    } else {
      // A pending trial is restarted; settled attempts are kept exactly once.
      _startCountdown();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
