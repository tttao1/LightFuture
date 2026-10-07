import 'dart:math';

import '../../models/game_catalog.dart';
import '../memory/memory_rules.dart';
import '../attention/attention_rules.dart';
import 'challenge.dart';
import '../logic/logic_rules.dart';
import '../calculation/calculation_rules.dart';
import '../reaction/timing_rules.dart';
import '../spatial/spatial_rules.dart';

Challenge createChallenge(GameId id, int level, Random random) {
  if (level < 1 || level > 10) throw RangeError.range(level, 1, 10, 'level');
  return switch (gameById(id).ability) {
    Ability.memory => memoryChallenge(id, level, random),
    Ability.attention => attentionChallenge(id, level, random),
    Ability.logic => logicChallenge(id, level, random),
    Ability.calculation => calculationChallenge(id, level, random),
    Ability.spatial => spatialChallenge(id, level, random),
    Ability.reaction => timingChallenge(id, level, random),
  };
}
