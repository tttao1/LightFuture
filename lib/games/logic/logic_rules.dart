import 'dart:math';
import '../../models/game_catalog.dart';
import '../shared/challenge.dart';

ChoiceChallenge numericChoices(
  String prompt,
  int answer,
  Random random,
  int level,
  String explanation,
) {
  final options = <int>{answer};
  while (options.length < (level <= 3 ? 3 : 4)) {
    options.add(answer + random.nextInt(21) - 10);
  }
  final values = options.toList()..shuffle(random);
  return ChoiceChallenge(
    prompt: prompt,
    options: values.map((v) => Choice('$v')).toList(),
    correctIndex: values.indexOf(answer),
    explanation: explanation,
    limit: Duration(seconds: 36 - level),
  );
}

Challenge logicChallenge(GameId id, int level, Random random) {
  if (id == GameId.numberPattern) {
    final first = random.nextInt(10) + 2;
    final step = random.nextInt(7) + 1;
    if (level <= 3) {
      final values = List.generate(4, (n) => first + step * n);
      return numericChoices(
        '等差数列：${values.join('、')}\n下一项是什么？',
        first + step * 4,
        random,
        level,
        '每次增加 $step',
      );
    }
    if (level <= 6 && random.nextBool()) {
      final factor = 2 + random.nextInt(2),
          values = List.generate(4, (n) => first * pow(factor, n).toInt());
      return numericChoices(
        '等比数列：${values.join('、')}\n下一项是什么？',
        first * pow(factor, 4).toInt(),
        random,
        level,
        '每次乘 $factor',
      );
    }
    if (level <= 8) {
      final secondStep = step + random.nextInt(4) + 1, values = <int>[first];
      for (var n = 0; n < 5; n++) {
        values.add(values.last + (n.isEven ? step : secondStep));
      }
      return numericChoices(
        '交替数列：${values.join('、')}\n下一项是什么？',
        values.last + secondStep,
        random,
        level,
        '交替增加 $step 和 $secondStep',
      );
    }
    final acceleration = 1 + random.nextInt(3);
    final values = List.generate(
      5,
      (n) => first + step * n + acceleration * n * n,
    );
    return numericChoices(
      '二阶差分数列：${values.join('、')}\n下一项是什么？',
      first + step * 5 + acceleration * 25,
      random,
      level,
      '相邻差值每次增加 ${acceleration * 2}',
    );
  }
  if (id == GameId.shapePattern) {
    final offset = random.nextInt(3);
    final shapes = level >= 8 ? [1, 3, 4] : [0, 1, 2];
    Visual at(int n) => Visual(
      shape: shapes[(n + offset) % 3],
      color: level <= 3 ? 0 : (n + offset) % 4,
      count: level >= 8 ? n % 3 + 1 : 1,
      turn: level >= 8 ? n % 2 : 0,
    );
    final target = at(5), candidates = <Visual>[target];
    while (candidates.length < 4) {
      final wrong = Visual(
        shape: random.nextInt(6),
        color: level <= 3 ? 0 : random.nextInt(4),
        count: level >= 8 ? random.nextInt(3) + 1 : 1,
        turn: 0,
      );
      if (candidates.every((v) => v.code != wrong.code)) candidates.add(wrong);
    }
    candidates.shuffle(random);
    return ChoiceChallenge(
      prompt: level <= 3
          ? '补全形状循环'
          : level <= 7
          ? '补全形状与颜色循环'
          : '同时观察形状、颜色、数量和方向',
      sequence: List.generate(5, at),
      options: candidates
          .asMap()
          .entries
          .map((e) => Choice('选项 ${e.key + 1}', visual: e.value))
          .toList(),
      correctIndex: candidates.indexOf(target),
      explanation: '按前五项的变化周期继续',
      limit: Duration(seconds: 35 - level),
    );
  }
  if (id == GameId.conditions) {
    final number = random.nextInt(40) + 1,
        color = random.nextInt(6),
        desiredColor = random.nextInt(6),
        threshold = 10 + random.nextInt(20);
    const names = ['紫色', '红色', '绿色', '黄色', '蓝色', '粉色'];
    final even = number.isEven,
        above = number > threshold,
        colorMatch = color == desiredColor;
    final (condition, answer) = level <= 3
        ? ('数字为偶数', even)
        : level <= 5
        ? ('（数字为偶数）且（数字大于 $threshold）', even && above)
        : level <= 7
        ? ('（数字为偶数）或（颜色为${names[desiredColor]}）', even || colorMatch)
        : level == 8
        ? ('（非偶数）且（颜色为${names[desiredColor]}）', !even && colorMatch)
        : (
            '（偶数且大于 $threshold）或（非${names[desiredColor]}）',
            (even && above) || !colorMatch,
          );
    return ChoiceChallenge(
      prompt: '条件：$condition\n下面的卡片是否符合？',
      word: '$number',
      wordColor: color,
      options: const [Choice('符合'), Choice('不符合')],
      correctIndex: answer ? 0 : 1,
      explanation: '数字 $number，颜色${names[color]}，${answer ? '符合' : '不符合'}条件',
      limit: Duration(seconds: 20 - level ~/ 2),
    );
  }
  if (id == GameId.numberSort) {
    final count = 4 + (level - 1) ~/ 2, numbers = <int>{};
    while (numbers.length < count) {
      numbers.add(random.nextInt(40 + level * 5) - (level >= 7 ? 20 : 0));
    }
    return SortChallenge(
      numbers: numbers.toList()..shuffle(random),
      descending: level >= 4 && random.nextBool(),
      limit: Duration(seconds: 42 - level * 2),
    );
  }
  throw ArgumentError('Not a logic game: $id');
}
