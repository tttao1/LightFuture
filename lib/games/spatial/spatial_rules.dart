import 'dart:collection';
import 'dart:math';
import '../../models/game_catalog.dart';
import '../shared/challenge.dart';

List<Cell> normalizeCells(Iterable<Cell> cells) {
  final list = cells.toList(),
      x = cells.map((p) => p.x).reduce(min),
      y = cells.map((p) => p.y).reduce(min);
  return list.map((p) => Cell(p.x - x, p.y - y)).toList()
    ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
}

List<Cell> rotateCells(List<Cell> cells, int turns) {
  var result = cells;
  for (var i = 0; i < turns % 4; i++) {
    result = result.map((p) => Cell(-p.y, p.x)).toList();
  }
  return normalizeCells(result);
}

String cellCode(Iterable<Cell> cells) =>
    normalizeCells(cells).map((p) => '${p.x}:${p.y}').join(';');
List<int> neighbors(int index, int size) => [
  if (index % size > 0) index - 1,
  if (index % size < size - 1) index + 1,
  if (index >= size) index - size,
  if (index < size * (size - 1)) index + size,
];
List<int>? shortestPath(int size, Set<int> blocked) {
  if (blocked.contains(0) || blocked.contains(size * size - 1)) return null;
  final queue = Queue<int>()..add(0), previous = <int, int>{0: -1};
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == size * size - 1) {
      final route = <int>[];
      for (var next = current; next >= 0; next = previous[next]!) {
        route.add(next);
      }
      return route.reversed.toList();
    }
    for (final next in neighbors(current, size)) {
      if (!blocked.contains(next) && !previous.containsKey(next)) {
        previous[next] = current;
        queue.add(next);
      }
    }
  }
  return null;
}

const _shape = [Cell(1, 0), Cell(2, 0), Cell(0, 1), Cell(1, 1), Cell(1, 2)];

Challenge spatialChallenge(GameId id, int level, Random random) {
  if (id == GameId.rotation) {
    final reference = Visual(cells: _shape, turn: random.nextInt(4) * 2);
    final target = Visual(
      cells: _shape,
      turn: level >= 8 ? random.nextInt(8) : random.nextInt(3) * 2 + 2,
    );
    final options = <Visual>[target];
    for (var i = 0; i < (level <= 3 ? 2 : 3); i++) {
      options.add(Visual(cells: _shape, mirrored: true, turn: i * 2));
    }
    options.shuffle(random);
    return ChoiceChallenge(
      prompt: '选择仅发生旋转的同一图形',
      reference: reference,
      options: options
          .asMap()
          .entries
          .map((e) => Choice('选项 ${e.key + 1}', visual: e.value))
          .toList(),
      correctIndex: options.indexOf(target),
      explanation: '正确图形只旋转，不发生镜像',
      limit: Duration(seconds: 30 - level),
    );
  }
  if (id == GameId.mirror) {
    final axis = level <= 3
        ? 0
        : level <= 7
        ? random.nextInt(2)
        : random.nextInt(3);
    final reflected = normalizeCells(
      _shape.map(
        (p) => axis == 0
            ? Cell(-p.x, p.y)
            : axis == 1
            ? Cell(p.x, -p.y)
            : Cell(p.y, p.x),
      ),
    );
    final matches = random.nextBool();
    final comparison = matches
        ? reflected
        : rotateCells(_shape, 1 + random.nextInt(3));
    return ChoiceChallenge(
      prompt: '沿${const ['竖直', '水平', '左上到右下对角'][axis]}镜轴翻转，右图是否正确？',
      reference: const Visual(cells: _shape),
      comparison: Visual(cells: comparison),
      options: const [Choice('是镜像'), Choice('不是镜像')],
      correctIndex: matches ? 0 : 1,
      explanation: matches ? '沿指定镜轴翻转后与右图一致' : '右图与指定镜像不一致',
      limit: Duration(seconds: 27 - level),
    );
  }
  if (id == GameId.blocks) {
    final size = level <= 3
            ? 3
            : level <= 7
            ? 4
            : 5,
        count = level <= 3
            ? 2
            : level <= 7
            ? 4
            : 5;
    final seeds = List.generate(size * size, (i) => i)..shuffle(random);
    final owners = <int, int>{for (var i = 0; i < count; i++) seeds[i]: i};
    while (owners.length < size * size) {
      final frontier = <(int, int)>[];
      for (final entry in owners.entries) {
        for (final next in neighbors(entry.key, size)) {
          if (!owners.containsKey(next)) frontier.add((next, entry.value));
        }
      }
      final next = frontier[random.nextInt(frontier.length)];
      owners[next.$1] = next.$2;
    }
    final solutions = List.generate(
      count,
      (i) => owners.entries
          .where((e) => e.value == i)
          .map((e) => Cell(e.key % size, e.key ~/ size))
          .toList(),
    );
    return BlockChallenge(
      size: size,
      solutions: solutions,
      pieces: solutions.map(normalizeCells).toList(),
      limit: Duration(seconds: 190 - level * 6),
    );
  }
  if (id == GameId.path) {
    final size = level <= 3
        ? 4
        : level <= 7
        ? 5
        : 6;
    for (var attempt = 0; attempt < 50; attempt++) {
      final blocked = <int>{
        for (var i = 1; i < size * size - 1; i++)
          if (random.nextDouble() < 0.1 + level * 0.018) i,
      };
      final route = shortestPath(size, blocked);
      if (route != null) {
        return PathChallenge(
          size: size,
          obstacles: blocked,
          shortest: route.length - 1,
          limit: Duration(seconds: 65 - level * 3),
        );
      }
    }
    return PathChallenge(
      size: size,
      obstacles: const {},
      shortest: (size - 1) * 2,
      limit: const Duration(seconds: 45),
    );
  }
  throw ArgumentError('Not a spatial game: $id');
}
