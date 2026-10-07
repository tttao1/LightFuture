import 'dart:math';

import '../../models/game_catalog.dart';
import '../shared/challenge.dart';

Challenge attentionChallenge(GameId id, int level, Random random) {
  if (id == GameId.schulte) {
    final size = level == 1
        ? 3
        : level == 2
        ? 4
        : 5;
    return SchulteChallenge(
      size: size,
      numbers: List.generate(size * size, (i) => i + 1)..shuffle(random),
      interference: max(0, level - 3),
      limit: Duration(
        seconds: const [90, 100, 120, 100, 75, 70, 65, 60, 50, 45][level - 1],
      ),
    );
  }
  if (id == GameId.differences) {
    final columns = level <= 3
        ? 3
        : level <= 7
        ? 4
        : 5;
    final rows = level <= 3
        ? 2
        : level <= 7
        ? 3
        : 4;
    final count = level <= 3
        ? 1
        : level <= 7
        ? 2
        : 3;
    final original = List.generate(
      columns * rows,
      (_) => Visual(shape: random.nextInt(6), color: random.nextInt(6)),
    );
    final changed = (List.generate(
      original.length,
      (i) => i,
    )..shuffle(random)).take(count).toSet();
    final comparison = List.generate(
      original.length,
      (i) => changed.contains(i)
          ? Visual(shape: (original[i].shape + 1) % 6, color: original[i].color)
          : original[i],
    );
    return GridChallenge(
      prompt: '对照上下两组，找出 $count 处变化',
      columns: columns,
      visuals: comparison,
      reference: original,
      targets: changed,
      limit: Duration(seconds: 52 - level * 2),
    );
  }
  if (id == GameId.targetSearch) {
    final columns = level <= 3
        ? 3
        : level <= 7
        ? 4
        : 5;
    final count = level <= 3
        ? 12
        : level <= 7
        ? 20
        : 30;
    final target = Visual(
      shape: level >= 8 ? 1 : random.nextInt(4),
      color: level <= 3 ? 0 : random.nextInt(6),
      turn: level >= 8 ? random.nextInt(8) : 0,
    );
    final targets = (List.generate(
      count,
      (i) => i,
    )..shuffle(random)).take(2 + level ~/ 3).toSet();
    final visuals = List.generate(count, (i) {
      if (targets.contains(i)) return target;
      Visual item;
      do {
        item = Visual(
          shape: random.nextInt(6),
          color: level <= 3 ? 0 : random.nextInt(6),
          turn: level >= 8 ? random.nextInt(8) : 0,
        );
      } while (item.code == target.code);
      return item;
    });
    return GridChallenge(
      prompt: '找齐与样例完全相同的图形',
      columns: columns,
      visuals: visuals,
      targets: targets,
      target: target,
      limit: Duration(seconds: 42 - level * 2),
    );
  }
  if (id == GameId.stroop) {
    const names = ['紫色', '红色', '绿色', '黄色', '蓝色', '粉色'];
    final count = min(6, 2 + (level - 1) ~/ 2),
        color = random.nextInt(count),
        word = random.nextInt(count);
    final order = List.generate(count, (i) => i)..shuffle(random);
    return ChoiceChallenge(
      prompt: '选择字体实际显示的颜色',
      word: names[word],
      wordColor: color,
      options: order.map((i) => Choice(names[i])).toList(),
      correctIndex: order.indexOf(color),
      explanation: '字体颜色是${names[color]}',
      limit: Duration(seconds: 12 - level ~/ 2),
    );
  }
  throw ArgumentError('Not an attention game: $id');
}
