import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/games/shared/challenge_board.dart';
import 'package:light_future_demo/games/shared/challenge_factory.dart';
import 'package:light_future_demo/models/game_catalog.dart';

Future<void> showBoard(
  WidgetTester tester,
  Challenge question,
  ValueChanged<RoundOutcome> done, {
  bool preview = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ChallengeBoard(
              challenge: question,
              preview: preview,
              elapsed: Duration.zero,
              done: done,
              progress: (_, _) {},
              feedback: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets(
    'all enabled boards fit a small phone at low and high difficulties',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final game in availableGames.where(
        (g) => g.id != GameId.reactionSpeed,
      )) {
        for (final level in [1, 5, 10]) {
          final question = createChallenge(game.id, level, Random(17));
          await showBoard(
            tester,
            question,
            (_) {},
            preview: question.preview > Duration.zero,
          );
          expect(tester.takeException(), isNull, reason: game.name);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );

  testWidgets(
    'grid selection requires all targets and rejects extra selections',
    (tester) async {
      final question =
          createChallenge(GameId.positionMemory, 1, Random(1)) as GridChallenge;
      final outcomes = <RoundOutcome>[];
      await showBoard(tester, question, outcomes.add);
      for (final target in question.targets) {
        await tapKey(tester, 'grid-$target');
      }
      final extra = List.generate(
        question.visuals.length,
        (i) => i,
      ).firstWhere((i) => !question.targets.contains(i));
      await tapKey(tester, 'grid-$extra');
      await tapKey(tester, 'submit-answer');
      expect(outcomes.single.correct, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('card pairing ignores a second tap on the same card', (
    tester,
  ) async {
    final question =
        createChallenge(GameId.cardPairs, 1, Random(3)) as PairChallenge;
    final outcomes = <RoundOutcome>[];
    await showBoard(tester, question, outcomes.add);
    for (final value in question.cards.toSet()) {
      final indexes = question.cards
          .asMap()
          .entries
          .where((e) => e.value == value)
          .map((e) => e.key)
          .toList();
      await tapKey(tester, 'card-${indexes.first}');
      await tapKey(tester, 'card-${indexes.first}');
      await tapKey(tester, 'card-${indexes.last}');
    }
    expect(outcomes.single.correct, isTrue);
    expect(outcomes.single.attempts, question.cards.length ~/ 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sequence reproduction accepts repeats and settles once', (
    tester,
  ) async {
    final question = SequenceChallenge(
      size: 4,
      sequence: [1, 1, 3],
      interval: const Duration(milliseconds: 500),
      preview: const Duration(seconds: 2),
      limit: const Duration(seconds: 10),
    );
    final outcomes = <RoundOutcome>[];
    await showBoard(tester, question, outcomes.add);
    for (final target in question.sequence) {
      await tapKey(tester, 'sequence-$target');
    }
    await tapKey(tester, 'sequence-3');
    expect(outcomes, hasLength(1));
    expect(outcomes.single.correct, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
