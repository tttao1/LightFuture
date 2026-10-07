enum Ability { memory, attention, reaction, logic, calculation, spatial }

extension AbilityLabel on Ability {
  String get label =>
      const ['记忆力', '注意力', '反应力', '逻辑能力', '计算能力', '空间能力'][index];
  String get hint => const [
    '记住信息与顺序',
    '聚焦目标，排除干扰',
    '把握时机，迅速行动',
    '发现规律，作出判断',
    '灵活运算，准确作答',
    '想象图形与路线',
  ][index];
}

enum GameId {
  numberMemory,
  positionMemory,
  cardPairs,
  sequenceMemory,
  schulte,
  differences,
  targetSearch,
  stroop,
  reactionSpeed,
  targetFlash,
  inhibition,
  rhythm,
  numberPattern,
  shapePattern,
  conditions,
  numberSort,
  arithmetic,
  chainedMath,
  comparison,
  makeNumber,
  rotation,
  mirror,
  blocks,
  path,
}

class GameDefinition {
  const GameDefinition(
    this.id,
    this.ability,
    this.name,
    this.summary,
    this.instructions, {
    this.rounds = 5,
  });
  final GameId id;
  final Ability ability;
  final String name;
  final String summary;
  final String instructions;
  final int rounds;
}

const allGames = <GameDefinition>[
  GameDefinition(
    GameId.numberMemory,
    Ability.memory,
    '数字记忆',
    '看清数字，隐藏后准确复述',
    '先记住数字串，隐藏后使用数字键盘输入原来的数字。每局五轮，数字中可能有 0。',
  ),
  GameDefinition(
    GameId.positionMemory,
    Ability.memory,
    '位置记忆',
    '找回刚才亮起的位置',
    '观察亮起的格子，隐藏后选中全部原位置再提交。多选或漏选都会计错。',
  ),
  GameDefinition(
    GameId.cardPairs,
    Ability.memory,
    '卡片配对',
    '翻开卡片，寻找相同图形',
    '每次翻开两张卡片，寻找相同的符号。找到所有配对完成训练；不匹配的卡片会自动翻回。',
    rounds: 1,
  ),
  GameDefinition(
    GameId.sequenceMemory,
    Ability.memory,
    '顺序记忆',
    '跟随光点，按顺序复现',
    '观察格子逐个亮起，然后按同样顺序点击。序列可能重复经过同一个位置。',
  ),
  GameDefinition(
    GameId.schulte,
    Ability.attention,
    '舒尔特方格',
    '依次寻找打乱的数字',
    '按 1、2、3……顺序点击全部数字。点错不会推进目标；完成越快越好。',
    rounds: 1,
  ),
  GameDefinition(
    GameId.differences,
    Ability.attention,
    '找不同',
    '对照图形，发现细微变化',
    '上方是原图，下方是对照图。选中下方所有发生变化的位置，再提交答案。',
  ),
  GameDefinition(
    GameId.targetSearch,
    Ability.attention,
    '目标搜索',
    '在干扰图形中找齐目标',
    '按照目标样例，选中所有完全相同的图形再提交。注意颜色、形状和方向。',
  ),
  GameDefinition(
    GameId.stroop,
    Ability.attention,
    '颜色干扰',
    '认字体颜色，忽略文字内容',
    '选择大字实际显示的颜色，而不是字的含义。颜色按钮的位置在每轮可能不同。',
  ),
  GameDefinition(
    GameId.reactionSpeed,
    Ability.reaction,
    '反应速度',
    '等待信号，立即点击',
    '蓝色时等待，绿色显示“立即点击”时点击。提前点算抢跑，未及时点算超时。每局五轮。',
  ),
  GameDefinition(
    GameId.targetFlash,
    Ability.reaction,
    '目标闪现',
    '捕捉不同位置的闪现目标',
    '目标出现后，尽快点击带闪电符号的格子。不要点击其他图形；位置会不断变化。',
  ),
  GameDefinition(
    GameId.inhibition,
    Ability.reaction,
    '抑制反应',
    '该点就点，禁止时忍住',
    '看到圆形目标就点击，看到叉形禁止符号不要点。目标漏点和禁止时误点都算错误。',
    rounds: 10,
  ),
  GameDefinition(
    GameId.rhythm,
    Ability.reaction,
    '节奏点击',
    '在标记经过判定线时点击',
    '圆点沿轨道移动，到达中央判定线时点击。每个节拍只点一次，以时间偏差评价。',
    rounds: 1,
  ),
  GameDefinition(
    GameId.numberPattern,
    Ability.logic,
    '数字规律',
    '发现数列的变化规则',
    '观察数字序列，从选项中选择下一项。题目由等差、等比、交替或二阶差分规则生成。',
  ),
  GameDefinition(
    GameId.shapePattern,
    Ability.logic,
    '图形规律',
    '补全形状和颜色序列',
    '观察图形的形状、颜色、方向或数量如何变化，从选项中补全缺失的下一项。',
  ),
  GameDefinition(
    GameId.conditions,
    Ability.logic,
    '条件判断',
    '按照条件作出是非判断',
    '阅读括号中的条件，再判断卡片是否符合。且表示同时满足，或表示满足其一，非表示不满足。',
  ),
  GameDefinition(
    GameId.numberSort,
    Ability.logic,
    '数字排序',
    '拖动卡片，排出正确顺序',
    '拖动数字卡片，按题目要求升序或降序排列，然后提交。每个数字只出现一次。',
  ),
  GameDefinition(
    GameId.arithmetic,
    Ability.calculation,
    '心算',
    '准确算出表达式的结果',
    '按照先乘除后加减、先括号的规则计算，用数字键盘输入答案。题目中的除法都能整除。',
  ),
  GameDefinition(
    GameId.chainedMath,
    Ability.calculation,
    '连续计算',
    '跟随运算，记住中间结果',
    '先记住初始数字，再观察运算步骤逐个出现。运算结束后，只输入最后的结果。',
  ),
  GameDefinition(
    GameId.comparison,
    Ability.calculation,
    '大小比较',
    '比较左右表达式的结果',
    '分别计算两边的结果，选择大于、小于或等于。必须判断结果，而不是数字长度。',
  ),
  GameDefinition(
    GameId.makeNumber,
    Ability.calculation,
    '凑数挑战',
    '组合数字与算符，达到目标',
    '使用给出的数字卡片构造表达式，使结果等于目标。每张卡片最多使用一次；按题目要求使用规定张数，支持括号与撤销。',
  ),
  GameDefinition(
    GameId.rotation,
    Ability.spatial,
    '图形旋转',
    '认出旋转后的同一图形',
    '选择与参考图相同、仅发生旋转的图形。镜像和结构变化都不是正确答案。',
  ),
  GameDefinition(
    GameId.mirror,
    Ability.spatial,
    '镜像判断',
    '沿指定镜轴想象映射',
    '观察镜轴的方向，判断右图是否恰好是左图沿该轴翻转后的结果。',
  ),
  GameDefinition(
    GameId.blocks,
    Ability.spatial,
    '方块拼合',
    '拖放拼块，填满目标轮廓',
    '选择拼块，可点击旋转，再拖到网格中锚点位置；也可以选择后点击网格放置。不能重叠或超出轮廓，覆盖全部目标即可。',
    rounds: 1,
  ),
  GameDefinition(
    GameId.path,
    Ability.spatial,
    '路径规划',
    '绕过障碍，走向终点',
    '从起点沿上下左右相邻格移动，可拖动或点击走下一步，不能穿过障碍。到达终点完成，路线越短得分越高。',
    rounds: 1,
  ),
];

GameDefinition gameById(GameId id) =>
    allGames.firstWhere((game) => game.id == id);

// Expanded in tested batches; no unfinished entries are shown to users.
const activeIds = {
  GameId.numberMemory,
  GameId.schulte,
  GameId.reactionSpeed,
  GameId.positionMemory,
  GameId.cardPairs,
  GameId.sequenceMemory,
  GameId.differences,
  GameId.targetSearch,
  GameId.stroop,
  GameId.numberPattern,
  GameId.shapePattern,
  GameId.conditions,
  GameId.numberSort,
  GameId.arithmetic,
  GameId.chainedMath,
  GameId.comparison,
  GameId.makeNumber,
  GameId.targetFlash,
  GameId.inhibition,
  GameId.rhythm,
  GameId.rotation,
  GameId.mirror,
  GameId.blocks,
  GameId.path,
};
List<GameDefinition> get availableGames =>
    allGames.where((g) => activeIds.contains(g.id)).toList();
