import 'dart:math';

import '../../models/game_catalog.dart';
import '../shared/challenge.dart';

Challenge memoryChallenge(GameId id, int level, Random random) {
  if (id == GameId.numberMemory) {
    final length = const [3, 4, 4, 5, 6, 6, 7, 8, 8, 9][level - 1];
    final answer = List.generate(length, (_) => random.nextInt(10)).join();
    return NumberChallenge(
      prompt: level >= 8 ? '只记数字，忽略颜色与背景干扰' : '记住数字，隐藏后准确输入',
      display: answer,
      answer: answer,
      interference: level >= 8,
      preview: Duration(milliseconds: 3200 - level * 120),
      limit: Duration(seconds: 16 - (level ~/ 2)),
    );
  }
  if (id == GameId.positionMemory) {
    final columns = level <= 3
        ? 3
        : level <= 7
        ? 4
        : 5;
    final count = 2 + ((level - 1) * 0.7).floor();
    final targets = (List.generate(
      columns * columns,
      (i) => i,
    )..shuffle(random)).take(count).toSet();
    return GridChallenge(
      prompt: '记住 $count 个亮起的位置',
      columns: columns,
      visuals: List.generate(columns * columns, (_) => const Visual(shape: 2)),
      targets: targets,
      hideTargets: true,
      preview: Duration(milliseconds: 3300 - 130 * level),
      limit: Duration(seconds: 23 - level),
    );
  }
  if (id == GameId.cardPairs) {
    final pairs = const [3, 4, 4, 5, 6, 7, 8, 8, 9, 10][level - 1];
    return PairChallenge(
      cards: [
        for (var i = 0; i < pairs; i++) ...[i, i],
      ]..shuffle(random),
      limit: Duration(seconds: 170 - level * 5),
    );
  }
  if (id == GameId.sequenceMemory) {
    final size = level <= 3
        ? 4
        : level <= 6
        ? 6
        : 9;
    final length = 3 + ((level - 1) * 0.7).floor();
    final interval = Duration(milliseconds: 840 - level * 40);
    return SequenceChallenge(
      size: size,
      sequence: List.generate(length, (_) => random.nextInt(size)),
      interval: interval,
      preview: Duration(milliseconds: interval.inMilliseconds * length + 500),
      limit: Duration(seconds: 22 - level),
    );
  }
  throw ArgumentError('Not a memory game: $id');
}
