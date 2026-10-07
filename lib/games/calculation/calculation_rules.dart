import 'dart:math';
import '../../models/game_catalog.dart';
import '../shared/challenge.dart';
import 'expression_rules.dart';

Challenge calculationChallenge(GameId id, int level, Random random) {
  if (id == GameId.arithmetic) {
    final a = random.nextInt(level <= 3 ? 20 : 90) + 1,
        b = random.nextInt(level <= 3 ? 20 : 50) + 1;
    String expression;
    if (level <= 3) {
      final total = random.nextInt(level * 20 + 1),
          part = random.nextInt(total + 1);
      expression = random.nextBool()
          ? '$part + ${total - part}'
          : '$total - $part';
    } else if (level <= 6) {
      expression = random.nextBool()
          ? '$a + $b'
          : '${2 + random.nextInt(10)} × ${2 + random.nextInt(8)}';
    } else if (level <= 8) {
      final divisor = 2 + random.nextInt(8), quotient = 2 + random.nextInt(12);
      expression = '${divisor * quotient} ÷ $divisor';
    } else {
      expression =
          '($a + $b) × ${2 + random.nextInt(5)} - ${random.nextInt(20)}';
    }
    return NumberChallenge(
      prompt: '心算：$expression',
      answer: evaluateExpression(expression).round().toString(),
      limit: Duration(seconds: 27 - level),
    );
  }
  if (id == GameId.chainedMath) {
    final initial = random.nextInt(15) + 5, steps = <String>[];
    var value = initial;
    final count = 2 + (level - 1) ~/ 2;
    for (var i = 0; i < count; i++) {
      final operand = 2 + random.nextInt(6),
          operation = random.nextInt(level >= 6 ? 4 : 2);
      if (operation == 2 && value.abs() * operand <= 600) {
        steps.add('× $operand');
        value *= operand;
      } else if (operation == 3 && value % operand == 0) {
        steps.add('÷ $operand');
        value ~/= operand;
      } else if (operation == 1) {
        steps.add('- $operand');
        value -= operand;
      } else {
        steps.add('+ $operand');
        value += operand;
      }
    }
    return NumberChallenge(
      prompt: '记住运算过程，输入最后的结果',
      display: '初始：$initial',
      steps: steps,
      answer: '$value',
      preview: Duration(milliseconds: (1600 - level * 40) * (steps.length + 1)),
      limit: Duration(seconds: 22 - level ~/ 2),
    );
  }
  if (id == GameId.comparison) {
    final a = random.nextInt(30) + 5,
        b = random.nextInt(20) + 1,
        multiplier = level >= 7 ? 2 + random.nextInt(4) : 1;
    final leftValue = (a + b) * multiplier;
    final relation = random.nextInt(3) - 1;
    final rightValue = leftValue - relation * (random.nextInt(5) + 1);
    final left = level <= 3
        ? '$leftValue'
        : multiplier == 1
        ? '$a + $b'
        : '($a + $b) × $multiplier';
    final x = random.nextInt(20) + 1,
        y = level >= 7 ? 2 + random.nextInt(3) : 1;
    final delta = rightValue - x * y;
    final right = level <= 3
        ? '$rightValue'
        : '$x${y == 1 ? '' : ' × $y'} ${delta >= 0 ? '+' : '-'} ${delta.abs()}';
    return ChoiceChallenge(
      prompt: '左边：$left\n右边：$right',
      options: const [Choice('左边大'), Choice('相等'), Choice('右边大')],
      correctIndex: relation == 0
          ? 1
          : relation > 0
          ? 0
          : 2,
      explanation: '左边=$leftValue，右边=$rightValue',
      limit: Duration(seconds: 20 - level ~/ 2),
    );
  }
  if (id == GameId.makeNumber) {
    final numbers = List.generate(
      level <= 3 ? 3 : 4,
      (_) => 1 + random.nextInt(level <= 6 ? 9 : 12),
    );
    final required = level <= 3
        ? 2
        : level <= 6
        ? 3
        : 4;
    final solution = required == 2
        ? '${numbers[0]}+${numbers[1]}'
        : required == 3
        ? '${numbers[0]}+${numbers[1]}-${numbers[2]}'
        : '(${numbers[0]}+${numbers[1]})*${numbers[2]}-${numbers[3]}';
    return ExpressionChallenge(
      numbers: numbers,
      requiredCards: required,
      solution: solution,
      target: evaluateExpression(solution).round(),
      allowMultiply: level >= 5,
      limit: Duration(seconds: 85 - level * 3),
    );
  }
  throw ArgumentError('Not a calculation game: $id');
}
