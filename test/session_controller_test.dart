import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/games/shared/session_controller.dart';
import 'package:light_future_demo/models/game_catalog.dart';

void main() {
  testWidgets(
    'paused ordinary games retain their question and exclude background time',
    (tester) async {
      final session = SessionController(
        gameById(GameId.schulte),
        1,
        nowMicros: () => tester.binding.clock.now().microsecondsSinceEpoch,
      );
      try {
        session.start();
        await tester.pump(const Duration(milliseconds: 3100));
        final question = session.challenge, revision = session.revision;
        final elapsed = session.phaseElapsed;
        session.progress(2, 3);
        session.pause();
        await tester.pump(const Duration(seconds: 20));
        expect(session.phaseElapsed, elapsed);
        session.resume();
        await tester.pump(const Duration(milliseconds: 3100));
        expect(session.phase, SessionPhase.playing);
        expect(identical(session.challenge, question), isTrue);
        expect(session.revision, revision);
        expect(session.phaseElapsed.inMilliseconds, lessThan(500));
        session.settle(
          const RoundOutcome(correct: true, correctCount: 9, attempts: 10),
        );
        session.settle(const RoundOutcome(correct: true));
        await tester.pump(const Duration(milliseconds: 1100));
        expect(session.outcomes.length, 1);
        expect(session.result.correct, 9);
        expect(session.result.attempts, 10);
        expect(session.result.seconds, lessThan(1));
      } finally {
        session.dispose();
      }
    },
  );
  testWidgets(
    'timing games restart interrupted trials and invalidate the old board',
    (tester) async {
      final session = SessionController(
        gameById(GameId.targetFlash),
        1,
        nowMicros: () => tester.binding.clock.now().microsecondsSinceEpoch,
      );
      try {
        session.start();
        await tester.pump(const Duration(milliseconds: 3100));
        final oldRevision = session.revision;
        session.pause();
        await tester.pump(const Duration(seconds: 10));
        session.resume();
        await tester.pump(const Duration(milliseconds: 3100));
        expect(session.revision, greaterThan(oldRevision));
        expect(session.outcomes, isEmpty);
      } finally {
        session.dispose();
      }
    },
  );
  testWidgets(
    'timeout retains partial progress and cannot produce a complete best result',
    (tester) async {
      final session = SessionController(
        gameById(GameId.schulte),
        1,
        nowMicros: () => tester.binding.clock.now().microsecondsSinceEpoch,
      );
      try {
        session.start();
        await tester.pump(const Duration(milliseconds: 3100));
        session.progress(4, 6);
        await tester.pump(const Duration(seconds: 92));
        expect(session.result.correct, 4);
        expect(session.result.attempts, 6);
        expect(session.result.completed, isFalse);
        expect(session.result.betterThan(null), isFalse);
      } finally {
        session.dispose();
      }
    },
  );
}
