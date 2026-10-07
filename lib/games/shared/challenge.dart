import 'dart:math';

typedef Cell = Point<int>;

class Visual {
  const Visual({
    this.shape = 0,
    this.color = 0,
    this.turn = 0,
    this.count = 1,
    this.cells,
    this.mirrored = false,
  });
  final int shape, color, turn, count;
  final List<Cell>? cells;
  final bool mirrored;
  String get code => '$shape:$color:$turn:$count';
}

sealed class Challenge {
  const Challenge({
    required this.prompt,
    required this.limit,
    this.preview = Duration.zero,
  });
  final String prompt;
  final Duration limit, preview;
  String get answerLabel;
}

class NumberChallenge extends Challenge {
  const NumberChallenge({
    required super.prompt,
    required super.limit,
    super.preview,
    required this.answer,
    this.display,
    this.steps = const [],
    this.interference = false,
  });
  final String answer;
  final String? display;
  final List<String> steps;
  final bool interference;
  @override
  String get answerLabel => answer;
}

class SchulteChallenge extends Challenge {
  const SchulteChallenge({
    required this.size,
    required this.numbers,
    required this.interference,
    required super.limit,
  }) : super(prompt: '依次点击 1 到最后一个数字');
  final int size, interference;
  final List<int> numbers;
  @override
  String get answerLabel => '按从小到大的顺序点击';
}

class GridChallenge extends Challenge {
  const GridChallenge({
    required super.prompt,
    required super.limit,
    super.preview,
    required this.columns,
    required this.visuals,
    required this.targets,
    this.reference,
    this.target,
    this.hideTargets = false,
  });
  final int columns;
  final List<Visual> visuals;
  final Set<int> targets;
  final List<Visual>? reference;
  final Visual? target;
  final bool hideTargets;
  @override
  String get answerLabel =>
      '目标位置：${(targets.toList()..sort()).map((i) => i + 1).join('、')}';
}

class SequenceChallenge extends Challenge {
  const SequenceChallenge({
    required this.size,
    required this.sequence,
    required this.interval,
    required super.limit,
    required super.preview,
  }) : super(prompt: '按刚才亮起的顺序点击');
  final int size;
  final List<int> sequence;
  final Duration interval;
  @override
  String get answerLabel => sequence.map((i) => i + 1).join(' → ');
}

class PairChallenge extends Challenge {
  const PairChallenge({required this.cards, required super.limit})
    : super(prompt: '找到所有相同的卡片');
  final List<int> cards;
  @override
  String get answerLabel => '翻开两个相同符号组成一对';
}

class Choice {
  const Choice(this.label, {this.visual});
  final String label;
  final Visual? visual;
}

class ChoiceChallenge extends Challenge {
  const ChoiceChallenge({
    required super.prompt,
    required super.limit,
    required this.options,
    required this.correctIndex,
    this.reference,
    this.comparison,
    this.sequence = const [],
    this.word,
    this.wordColor = 0,
    this.explanation = '',
  });
  final List<Choice> options;
  final int correctIndex;
  final Visual? reference, comparison;
  final List<Visual> sequence;
  final String? word;
  final int wordColor;
  final String explanation;
  @override
  String get answerLabel => explanation.isEmpty
      ? options[correctIndex].label
      : '${options[correctIndex].label} · $explanation';
}

class SortChallenge extends Challenge {
  const SortChallenge({
    required this.numbers,
    required this.descending,
    required super.limit,
  }) : super(prompt: descending ? '拖动数字，按从大到小排列' : '拖动数字，按从小到大排列');
  final List<int> numbers;
  final bool descending;
  List<int> get answer =>
      List.of(numbers)
        ..sort((a, b) => descending ? b.compareTo(a) : a.compareTo(b));
  @override
  String get answerLabel => answer.join('、');
}

class ExpressionChallenge extends Challenge {
  const ExpressionChallenge({
    required this.numbers,
    required this.target,
    required this.requiredCards,
    required this.solution,
    required this.allowMultiply,
    required super.limit,
  }) : super(prompt: '组合卡片与算符，得到目标');
  final List<int> numbers;
  final int target, requiredCards;
  final String solution;
  final bool allowMultiply;
  @override
  String get answerLabel => '一种解法：$solution = $target';
}

class BlockChallenge extends Challenge {
  const BlockChallenge({
    required this.size,
    required this.pieces,
    required this.solutions,
    required super.limit,
  }) : super(prompt: '放置拼块，填满全部目标格子');
  final int size;
  final List<List<Cell>> pieces, solutions;
  @override
  String get answerLabel => '每块不重叠、不出界，覆盖整张网格即可';
}

class PathChallenge extends Challenge {
  const PathChallenge({
    required this.size,
    required this.obstacles,
    required this.shortest,
    required super.limit,
  }) : super(prompt: '绕开障碍，从起点走到终点');
  final int size, shortest;
  final Set<int> obstacles;
  @override
  String get answerLabel => '最短路线需要 $shortest 步';
}

enum TimingKind { flash, inhibition, rhythm }

class TimingChallenge extends Challenge {
  const TimingChallenge({
    required this.kind,
    required this.columns,
    required this.targetIndex,
    required this.delay,
    required this.window,
    this.shouldTap = true,
    this.beats = const [],
    this.tolerance = 180,
    required super.limit,
  }) : super(
         prompt: kind == TimingKind.inhibition
             ? '圆形要点，叉形不点'
             : kind == TimingKind.rhythm
             ? '经过中央判定线时点击'
             : '捕捉闪电目标',
       );
  final TimingKind kind;
  final int columns, targetIndex, tolerance;
  final Duration delay, window;
  final bool shouldTap;
  final List<int> beats;
  @override
  String get answerLabel => kind == TimingKind.inhibition
      ? (shouldTap ? '看到圆形需要点击' : '看到叉形不要点击')
      : '把握信号出现的时机';
}

class RoundOutcome {
  const RoundOutcome({
    required this.correct,
    this.correctCount = 0,
    this.attempts = 1,
    this.completed = true,
    this.quality = 1,
    this.detail = '',
  });
  final bool correct, completed;
  final int correctCount, attempts;
  final double quality;
  final String detail;
  int get hits => correctCount > 0
      ? correctCount
      : correct
      ? 1
      : 0;
}
