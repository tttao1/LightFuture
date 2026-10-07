import 'dart:math';
import '../../models/game_catalog.dart';
import '../shared/challenge.dart';

Challenge timingChallenge(GameId id, int level, Random random) {
  final delay = Duration(milliseconds: 700 + random.nextInt(1000));
  final window = Duration(milliseconds: 1600 - level * 85);
  if (id == GameId.targetFlash || id == GameId.inhibition) {
    final columns = level <= 3
        ? 2
        : level <= 7
        ? 3
        : 4;
    final count = columns == 4 ? 12 : columns * columns;
    return TimingChallenge(
      kind: id == GameId.targetFlash ? TimingKind.flash : TimingKind.inhibition,
      columns: columns,
      targetIndex: random.nextInt(count),
      delay: delay,
      window: window,
      shouldTap: random.nextBool(),
      limit: delay + window + const Duration(seconds: 2),
    );
  }
  if (id == GameId.rhythm) {
    final beats = <int>[1800];
    for (var i = 1; i < 8 + (level - 1) ~/ 2; i++) {
      beats.add(
        beats.last +
            1100 -
            level * 35 +
            (level >= 5 ? random.nextInt(161) - 80 : 0),
      );
    }
    final tolerance = 230 - level * 12;
    return TimingChallenge(
      kind: TimingKind.rhythm,
      columns: 1,
      targetIndex: 0,
      delay: Duration.zero,
      window: window,
      beats: beats,
      tolerance: tolerance,
      limit: Duration(milliseconds: beats.last + tolerance + 1200),
    );
  }
  throw ArgumentError('Not a timing game: $id');
}
