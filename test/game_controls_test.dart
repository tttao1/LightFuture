import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/games/shared/challenge_factory.dart';
import 'package:light_future_demo/games/shared/session_controller.dart';
import 'package:light_future_demo/games/spatial/spatial_rules.dart';
import 'package:light_future_demo/models/game_catalog.dart';
import 'package:light_future_demo/pages/training_page.dart';
import 'boards_test.dart' show showBoard, tapKey;
import 'widget_test.dart' show testStore, visibleTap;

void main() {
  testWidgets(
    'sorting is an editable permutation and validates the entire order',
    (tester) async {
      final outcomes = <RoundOutcome>[];
      await showBoard(
        tester,
        const SortChallenge(
          numbers: [3, 1, 2],
          descending: false,
          limit: Duration(seconds: 20),
        ),
        outcomes.add,
      );
      await tapKey(tester, 'sort-up-1');
      await tapKey(tester, 'sort-up-2');
      await tapKey(tester, 'submit-answer');
      expect(outcomes.single.correct, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'number cards cannot be reused or concatenated without an operator',
    (tester) async {
      final outcomes = <RoundOutcome>[];
      await showBoard(
        tester,
        const ExpressionChallenge(
          numbers: [2, 3, 8],
          target: 5,
          requiredCards: 2,
          solution: '2+3',
          allowMultiply: false,
          limit: Duration(seconds: 20),
        ),
        outcomes.add,
      );
      await tapKey(tester, 'number-card-0');
      await tapKey(tester, 'number-card-1');
      expect(find.text('2'), findsWidgets);
      expect(find.text('23'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tapKey(tester, 'operator-+');
      await tapKey(tester, 'number-card-1');
      await tapKey(tester, 'submit-answer');
      expect(outcomes.single.correct, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'block pieces can be placed using a legal witness and cannot overlap',
    (tester) async {
      final question =
          createChallenge(GameId.blocks, 1, Random(11)) as BlockChallenge;
      final outcomes = <RoundOutcome>[];
      await showBoard(tester, question, outcomes.add);
      for (var i = 0; i < question.pieces.length; i++) {
        final x = question.solutions[i].map((p) => p.x).reduce(min),
            y = question.solutions[i].map((p) => p.y).reduce(min);
        await tapKey(tester, 'piece-$i');
        await tapKey(tester, 'block-${y * question.size + x}');
      }
      expect(outcomes.single.correct, isTrue);
      expect(outcomes.single.correctCount, question.size * question.size);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'path game permits adjacent moves and reaches a reachable target',
    (tester) async {
      final question =
          createChallenge(GameId.path, 1, Random(2)) as PathChallenge;
      final outcomes = <RoundOutcome>[];
      await showBoard(tester, question, outcomes.add);
      for (final next in shortestPath(
        question.size,
        question.obstacles,
      )!.skip(1)) {
        await tapKey(tester, 'path-$next');
      }
      expect(outcomes.single.correct, isTrue);
      expect(outcomes.single.correctCount, question.shortest);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'inhibition rewards waiting on a forbidden signal and rejects clicking it',
    (tester) async {
      final outcomes = <RoundOutcome>[];
      const question = TimingChallenge(
        kind: TimingKind.inhibition,
        columns: 2,
        targetIndex: 0,
        delay: Duration(milliseconds: 100),
        window: Duration(milliseconds: 500),
        shouldTap: false,
        limit: Duration(seconds: 3),
      );
      await showBoard(tester, question, outcomes.add);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 600));
      expect(outcomes.single.correct, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      outcomes.clear();
      await showBoard(tester, question, outcomes.add);
      await tester.pump(const Duration(milliseconds: 150));
      await tapKey(tester, 'inhibition-tap');
      expect(outcomes.single.correct, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'rhythm beats accept one hit each and settle after the final beat',
    (tester) async {
      final outcomes = <RoundOutcome>[];
      const question = TimingChallenge(
        kind: TimingKind.rhythm,
        columns: 1,
        targetIndex: 0,
        delay: Duration.zero,
        window: Duration(seconds: 1),
        beats: [1000, 2000],
        tolerance: 100,
        limit: Duration(seconds: 4),
      );
      await showBoard(tester, question, outcomes.add);
      await tester.pump(const Duration(seconds: 1));
      await tapKey(tester, 'rhythm-tap');
      await tester.pump(const Duration(seconds: 1));
      await tapKey(tester, 'rhythm-tap');
      await tester.pump(const Duration(milliseconds: 400));
      expect(outcomes.single.correctCount, 2);
      expect(outcomes.single.attempts, 2);
      expect(outcomes.single.quality, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'ordinary game boards keep their progress across pause and resume',
    (tester) async {
      final store = await testStore(), game = gameById(GameId.schulte);
      final session = SessionController(
        game,
        1,
        nowMicros: () => tester.binding.clock.now().microsecondsSinceEpoch,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TrainingPage(
            game: game,
            level: 1,
            store: store,
            controller: session,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 3100));
      await visibleTap(tester, find.byKey(const Key('schulte-1')));
      await tester.tap(find.byTooltip('暂停训练'));
      await tester.pump();
      expect(find.text('训练已暂停'), findsOneWidget);
      await visibleTap(tester, find.byKey(const Key('continue-training')));
      await tester.pump(const Duration(milliseconds: 3100));
      expect(find.text('下一目标：2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
}
