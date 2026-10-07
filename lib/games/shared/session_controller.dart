import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/game_catalog.dart';
import '../../models/training_result.dart';
import 'challenge.dart';
import 'challenge_factory.dart';

enum SessionPhase { countdown, preview, playing, feedback, paused, finished }

class SessionController extends ChangeNotifier {
  SessionController(
    this.game,
    this.level, {
    Random? random,
    int Function()? nowMicros,
  }) : random = random ?? Random(),
       _nowMicros = nowMicros;
  final GameDefinition game;
  final int level;
  final Random random;
  final Stopwatch _clock = Stopwatch()..start(), _totalClock = Stopwatch();
  final int Function()? _nowMicros;
  int _phaseStarted = 0, _partialHits = 0, _partialAttempts = 0;
  Timer? _ticker;
  bool _closed = false;
  SessionPhase _pausedFrom = SessionPhase.countdown;
  SessionPhase? _resumePhase;
  Duration _frozenElapsed = Duration.zero, _resumeElapsed = Duration.zero;
  SessionPhase phase = SessionPhase.countdown;
  Challenge? challenge;
  int round = 0, revision = 0;
  final List<RoundOutcome> outcomes = [];
  double _playSeconds = 0;

  int get _now => _nowMicros?.call() ?? _clock.elapsedMicroseconds;
  Duration get phaseElapsed => phase == SessionPhase.paused
      ? _frozenElapsed
      : Duration(microseconds: max(0, _now - _phaseStarted));
  int get countdown => max(1, 3 - phaseElapsed.inSeconds);
  double get remaining => max(
    0,
    ((challenge?.limit.inMilliseconds ?? 0) - phaseElapsed.inMilliseconds) /
        1000,
  );
  double get previewRemaining => max(
    0,
    ((challenge?.preview.inMilliseconds ?? 0) - phaseElapsed.inMilliseconds) /
        1000,
  );
  double get seconds => _totalClock.elapsedMilliseconds / 1000;

  void start() {
    _ticker?.cancel();
    outcomes.clear();
    round = 0;
    _playSeconds = 0;
    _resumePhase = null;
    challenge = null;
    _totalClock
      ..reset()
      ..start();
    _enter(SessionPhase.countdown);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
  }

  void _enter(SessionPhase next) {
    phase = next;
    _phaseStarted = _now;
    _notify();
  }

  void _newRound() {
    challenge = createChallenge(game.id, level, random);
    _partialHits = 0;
    _partialAttempts = 0;
    round = outcomes.length + 1;
    revision++;
    _enter(
      challenge!.preview > Duration.zero
          ? SessionPhase.preview
          : SessionPhase.playing,
    );
  }

  void tick() {
    if (_closed ||
        phase == SessionPhase.paused ||
        phase == SessionPhase.finished) {
      return;
    }
    if (phase == SessionPhase.countdown &&
        phaseElapsed >= const Duration(seconds: 3)) {
      if (_resumePhase != null) {
        phase = _resumePhase!;
        _resumePhase = null;
        _phaseStarted = _now - _resumeElapsed.inMicroseconds;
        _notify();
      } else {
        _newRound();
      }
    } else if (phase == SessionPhase.preview &&
        phaseElapsed >= challenge!.preview) {
      _enter(SessionPhase.playing);
    } else if (phase == SessionPhase.playing &&
        phaseElapsed >= challenge!.limit) {
      settle(
        RoundOutcome(
          correct: false,
          correctCount: _partialHits,
          attempts: max(1, _partialAttempts),
          completed: false,
          detail: '时间到了',
        ),
      );
    } else if (phase == SessionPhase.feedback &&
        phaseElapsed >= const Duration(milliseconds: 1000)) {
      if (outcomes.length >= game.rounds) {
        _finish();
      } else {
        _newRound();
      }
    } else {
      _notify();
    }
  }

  void settle(RoundOutcome outcome) {
    if (_closed || phase != SessionPhase.playing) return;
    if (phaseElapsed >= challenge!.limit && outcome.completed) {
      outcome = RoundOutcome(
        correct: false,
        correctCount: _partialHits,
        attempts: max(1, _partialAttempts),
        completed: false,
        detail: '时间到了',
      );
    }
    if (outcome.correct &&
        outcome.quality == 1 &&
        challenge is! TimingChallenge) {
      outcome = RoundOutcome(
        correct: true,
        correctCount: outcome.correctCount,
        attempts: outcome.attempts,
        completed: outcome.completed,
        quality:
            (1 - phaseElapsed.inMilliseconds / challenge!.limit.inMilliseconds)
                .clamp(0.15, 1.0),
        detail: outcome.detail,
      );
    }
    _playSeconds += phaseElapsed.inMilliseconds / 1000;
    outcomes.add(outcome);
    _enter(SessionPhase.feedback);
  }

  void pause() {
    if (_closed ||
        phase == SessionPhase.paused ||
        phase == SessionPhase.finished) {
      return;
    }
    _ticker?.cancel();
    _totalClock.stop();
    final restarting = phase == SessionPhase.countdown && _resumePhase != null;
    _frozenElapsed = restarting ? _resumeElapsed : phaseElapsed;
    _pausedFrom = restarting ? _resumePhase! : phase;
    phase = SessionPhase.paused;
    _notify();
  }

  void resume() {
    if (_closed || phase != SessionPhase.paused) return;
    if (outcomes.length >= game.rounds) {
      _finish();
      return;
    }
    _totalClock.start();
    final restartTiming =
        challenge is TimingChallenge && _pausedFrom == SessionPhase.playing;
    _resumePhase = restartTiming || _pausedFrom == SessionPhase.countdown
        ? null
        : _pausedFrom;
    _resumeElapsed = _frozenElapsed;
    _enter(SessionPhase.countdown);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
  }

  void _finish() {
    _ticker?.cancel();
    _totalClock.stop();
    phase = SessionPhase.finished;
    _notify();
  }

  TrainingResult get result {
    final attempts = outcomes.fold<int>(0, (sum, o) => sum + o.attempts);
    final correct = outcomes.fold<int>(0, (sum, o) => sum + o.hits);
    final accuracy = attempts == 0 ? 0.0 : correct / attempts;
    final completion =
        outcomes.isNotEmpty && outcomes.every((o) => o.completed);
    final quality = outcomes.isEmpty
        ? 0.0
        : outcomes.fold<double>(
                0,
                (sum, o) => sum + (o.correct ? o.quality : 0),
              ) /
              outcomes.length;
    return TrainingResult(
      game: game.id,
      level: level,
      score: (700 * accuracy + 300 * quality).round().clamp(0, 1000),
      correct: correct,
      attempts: attempts,
      seconds: _playSeconds,
      completed: completion,
      metrics: {
        '完成轮次': '${outcomes.length}/${game.rounds}',
        if (outcomes.isNotEmpty && outcomes.last.detail.isNotEmpty)
          '训练反馈': outcomes.last.detail,
      },
    );
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  void progress(int correct, int attempts) {
    _partialHits = max(0, correct);
    _partialAttempts = max(_partialHits, attempts);
  }

  @override
  void dispose() {
    _closed = true;
    _ticker?.cancel();
    _clock.stop();
    _totalClock.stop();
    super.dispose();
  }
}
