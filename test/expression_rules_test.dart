import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/calculation/expression_rules.dart';
import 'dart:math';
import 'package:light_future_demo/games/shared/challenge_factory.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/models/game_catalog.dart';

void main() {
  test('introductory arithmetic stays within non-negative twenty', () {
    for (var seed = 0; seed < 200; seed++) {
      final question =
          createChallenge(GameId.arithmetic, 1, Random(seed))
              as NumberChallenge;
      expect(int.parse(question.answer), inInclusiveRange(0, 20));
    }
  });
  test(
    'operator precedence, parentheses, negative values and exact divisions',
    () {
      expect(evaluateExpression('2 + 3 × 4'), 14);
      expect(evaluateExpression('(2 + 3) × 4'), 20);
      expect(evaluateExpression('6 ÷ 2 - 8'), -5);
      expect(evaluateExpression('3 * (-2)'), -6);
      expect(evaluateExpression('1 / 2 + 1 / 2'), 1);
    },
  );
  test(
    'incomplete input, unexpected characters and division by zero are rejected',
    () {
      for (final expression in [
        '',
        '3+',
        '(2+4',
        '2)3',
        '2a',
        '1/0',
        '2**3',
        '()',
      ]) {
        expect(
          () => evaluateExpression(expression),
          throwsFormatException,
          reason: expression,
        );
      }
    },
  );
}
