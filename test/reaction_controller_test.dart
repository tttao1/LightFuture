import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/reaction_controller.dart';

void main() {
  ReactionController create({int Function()? now}) => ReactionController(
    level: 1,
    nowMicros: now,
    waitingDuration: () => const Duration(seconds: 2),
  );

  testWidgets('countdown taps are ignored; early taps settle only once', (
    tester,
  ) async {
    final game = create();
    try {
      game.start();
      game.tap();
      expect(game.attempts, isEmpty);
      await tester.pump(const Duration(seconds: 3));
      expect(game.phase, ReactionPhase.waiting);
      game.tap();
      game.tap();
      expect(game.attempts, hasLength(1));
      expect(game.lastAttempt!.outcome, AttemptOutcome.falseStart);
      await tester.pump(ReactionController.feedbackDuration);
      expect(game.currentRound, 2);
      expect(game.phase, ReactionPhase.waiting);
    } finally {
      game.dispose();
    }
  });

  testWidgets(
    'timing begins with the displayed signal; stale frames are ignored',
    (tester) async {
      var now = 0;
      final game = create(now: () => now);
      try {
        game.start();
        await tester.pump(const Duration(seconds: 5));
        expect(game.phase, ReactionPhase.ready);
        game.tap();
        expect(game.attempts, isEmpty);
        game.signalFramePresented(game.signalToken - 1);
        game.tap();
        expect(game.attempts, isEmpty);
        now = 9000000;
        game.signalFramePresented(game.signalToken);
        now += 250000;
        game.tap();
        expect(game.lastAttempt!.outcome, AttemptOutcome.success);
        expect(game.lastAttempt!.milliseconds, 250);
        expect(game.summary.averageMilliseconds, 250);
        game.tap();
        expect(game.attempts, hasLength(1));
      } finally {
        game.dispose();
      }
    },
  );

  testWidgets('late input cannot bypass a response deadline', (tester) async {
    var now = 0;
    final game = create(now: () => now);
    try {
      game.start();
      await tester.pump(const Duration(seconds: 5));
      game.signalFramePresented(game.signalToken);
      now = 1500000;
      game.tap();
      expect(game.lastAttempt!.outcome, AttemptOutcome.timeout);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(game.attempts, hasLength(1));
    } finally {
      game.dispose();
    }
  });

  testWidgets('no response times out; five settled trials finish the session', (
    tester,
  ) async {
    final game = create();
    try {
      game.start();
      await tester.pump(const Duration(seconds: 3));
      for (var round = 0; round < 5; round++) {
        await tester.pump(const Duration(seconds: 2));
        expect(game.phase, ReactionPhase.ready);
        game.signalFramePresented(game.signalToken);
        await tester.pump(Duration(milliseconds: game.responseLimit));
        expect(game.lastAttempt!.outcome, AttemptOutcome.timeout);
        await tester.pump(ReactionController.feedbackDuration);
      }
      expect(game.phase, ReactionPhase.finished);
      expect(game.summary.timeouts, 5);
      expect(game.summary.accuracy, 0);
      expect(game.summary.averageMilliseconds, isNull);
      expect(game.summary.score, 0);
      expect(game.summary.isBetterThan(null), isFalse);
    } finally {
      game.dispose();
    }
  });

  testWidgets(
    'pause cancels the unfinished trial and preserves completed trials',
    (tester) async {
      final game = create();
      try {
        game.start();
        await tester.pump(const Duration(seconds: 3));
        game.tap();
        game.pause();
        await tester.pump(const Duration(seconds: 30));
        expect(game.phase, ReactionPhase.paused);
        expect(game.attempts, hasLength(1));
        game.resume();
        expect(game.currentRound, 2);
        expect(game.phase, ReactionPhase.countdown);
        await tester.pump(const Duration(seconds: 5));
        game.signalFramePresented(game.signalToken);
        game.pause();
        await tester.pump(const Duration(seconds: 30));
        expect(game.attempts, hasLength(1));
        game.resume();
        expect(game.currentRound, 2);
      } finally {
        game.dispose();
      }
    },
  );

  testWidgets('pause in the final feedback does not create a sixth trial', (
    tester,
  ) async {
    final game = create();
    try {
      game.start();
      await tester.pump(const Duration(seconds: 3));
      for (var round = 0; round < 4; round++) {
        game.tap();
        await tester.pump(ReactionController.feedbackDuration);
      }
      game.tap();
      game.pause();
      game.resume();
      expect(game.phase, ReactionPhase.finished);
      expect(game.attempts, hasLength(5));
    } finally {
      game.dispose();
    }
  });

  testWidgets('restarting clears results; disposal cancels pending timers', (
    tester,
  ) async {
    final game = create();
    game.start();
    await tester.pump(const Duration(seconds: 3));
    game.tap();
    game.start();
    expect(game.attempts, isEmpty);
    expect(game.countdown, 3);
    game.dispose();
    await tester.pump(const Duration(seconds: 30));
    expect(tester.takeException(), isNull);
  });

  test('best result favors successful completion before speed', () {
    ReactionSummary result(int successes, int milliseconds) => ReactionSummary(
      level: 1,
      attempts: List.generate(
        5,
        (i) => i < successes
            ? ReactionAttempt(
                AttemptOutcome.success,
                milliseconds: milliseconds,
              )
            : const ReactionAttempt(AttemptOutcome.falseStart),
      ),
    );
    expect(result(5, 600).isBetterThan(result(4, 100)), isTrue);
    expect(result(5, 200).isBetterThan(result(5, 600)), isTrue);
    expect(result(5, 200).isBetterThan(result(5, 200)), isFalse);
    expect(result(5, 200).score, inInclusiveRange(0, 1000));
  });
}
