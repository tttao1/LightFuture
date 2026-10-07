import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/games/shared/challenge_factory.dart';
import 'package:light_future_demo/models/game_catalog.dart';
import 'package:light_future_demo/games/calculation/expression_rules.dart';

void main() {
  test('all enabled games generate valid challenges at every difficulty', () {
    for (final game in availableGames.where(
      (g) => g.id != GameId.reactionSpeed,
    )) {
      for (var level = 1; level <= 10; level++) {
        for (var seed = 0; seed < 20; seed++) {
          final question = createChallenge(game.id, level, Random(seed));
          expect(
            question.limit.inMilliseconds,
            greaterThan(0),
            reason: game.name,
          );
          expect(question.answerLabel, isNotEmpty);
          if (question is NumberChallenge) {
            if (game.id == GameId.numberMemory) {
              expect(question.answer.length, inInclusiveRange(3, 9));
              expect(question.display, question.answer);
            } else {
              expect(int.tryParse(question.answer), isNotNull);
              if (question.steps.isNotEmpty) {
                var value = double.parse(
                  RegExp(r'-?\d+').firstMatch(question.display!)!.group(0)!,
                );
                for (final step in question.steps) {
                  value = evaluateExpression(
                    '($value)${step.replaceAll(' ', '')}'.replaceAll(
                      '.0)',
                      ')',
                    ),
                  );
                }
                expect(value, double.parse(question.answer));
              } else if (game.id == GameId.arithmetic) {
                expect(
                  evaluateExpression(question.prompt.substring('心算：'.length)),
                  double.parse(question.answer),
                );
              }
            }
          } else if (question is SchulteChallenge) {
            expect(
              question.numbers.toSet().length,
              question.size * question.size,
            );
            expect(
              question.numbers.toSet(),
              containsAll(
                List.generate(question.size * question.size, (i) => i + 1),
              ),
            );
          } else if (question is GridChallenge) {
            expect(question.targets, isNotEmpty);
            expect(
              question.targets.every(
                (i) => i >= 0 && i < question.visuals.length,
              ),
              isTrue,
            );
            if (question.target != null) {
              final matches = question.visuals
                  .asMap()
                  .entries
                  .where((e) => e.value.code == question.target!.code)
                  .map((e) => e.key)
                  .toSet();
              expect(matches, question.targets);
            }
            if (question.reference != null) {
              final differences = question.visuals
                  .asMap()
                  .entries
                  .where((e) => e.value.code != question.reference![e.key].code)
                  .map((e) => e.key)
                  .toSet();
              expect(differences, question.targets);
            }
          } else if (question is PairChallenge) {
            for (final card in question.cards.toSet()) {
              expect(question.cards.where((c) => c == card).length, 2);
            }
          } else if (question is SequenceChallenge) {
            expect(
              question.sequence.every((i) => i >= 0 && i < question.size),
              isTrue,
            );
            expect(
              question.preview.inMilliseconds,
              greaterThan(
                question.sequence.length * question.interval.inMilliseconds,
              ),
            );
          } else if (question is ExpressionChallenge) {
            expect(evaluateExpression(question.solution), question.target);
            expect(
              question.requiredCards,
              lessThanOrEqualTo(question.numbers.length),
            );
          } else if (question is SortChallenge) {
            expect(question.numbers.toSet().length, question.numbers.length);
            expect(question.answer.toSet(), question.numbers.toSet());
          } else if (question is ChoiceChallenge) {
            expect(
              question.correctIndex,
              inInclusiveRange(0, question.options.length - 1),
            );
            expect(
              question.options.map((o) => o.label).toSet().length,
              question.options.length,
            );
          }
        }
      }
    }
  });
}
