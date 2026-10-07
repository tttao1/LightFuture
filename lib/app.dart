import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'games/reaction_controller.dart';

const _ink = Color(0xFF17213F);
const _purple = Color(0xFF6656E8);
const _green = Color(0xFF16A578);
typedef BestRecorder = bool Function(ReactionSummary result);

class BrainTrainingDemo extends StatefulWidget {
  const BrainTrainingDemo({super.key});

  @override
  State<BrainTrainingDemo> createState() => _BrainTrainingDemoState();
}

class _BrainTrainingDemoState extends State<BrainTrainingDemo> {
  final Map<int, ReactionSummary> _best = {};

  bool _record(ReactionSummary result) {
    if (!result.isBetterThan(_best[result.level])) return false;
    setState(() => _best[result.level] = result);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '脑力训练 Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _purple),
        scaffoldBackgroundColor: const Color(0xFFF5F6FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6FC),
          foregroundColor: _ink,
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, height: 1.6),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        ).apply(bodyColor: _ink, displayColor: _ink),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: _HomePage(best: _best, record: _record),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({required this.best, required this.record});

  final Map<int, ReactionSummary> best;
  final BestRecorder record;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    final best = widget.best[_level];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const Icon(Icons.bubble_chart_rounded, color: _purple, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('脑力训练', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const _Tag('离线 Demo', color: _green),
                  ],
                ),
                const SizedBox(height: 30),
                Text('专注这一刻', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                const Text('来一次轻松的反应训练。',
                    style: TextStyle(color: Color(0xFF747B94))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF28376B), Color(0xFF6656E8)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt_rounded, size: 58, color: Color(0xFFCCCAFF)),
                      SizedBox(height: 16),
                      Text('反应速度',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text('等待绿色信号，尽快点击。\n5 轮小挑战，看看你的反应有多快。',
                          style: TextStyle(color: Color(0xFFEBEAFF), height: 1.7)),
                      SizedBox(height: 20),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _Tag('5 轮训练', color: Colors.white, dark: true),
                        _Tag('10 个等级', color: Colors.white, dark: true),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('选择难度',
                                style: Theme.of(context).textTheme.titleMedium)),
                        _Tag('Level $_level'),
                      ]),
                      const SizedBox(height: 12),
                      Slider(
                        key: const Key('difficulty-slider'),
                        value: _level.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: 'Level $_level',
                        onChanged: (value) => setState(() => _level = value.round()),
                      ),
                      Text(
                        '绿色信号出现后，在 ${ReactionController.responseLimitFor(_level)} 毫秒内点击。',
                        style: const TextStyle(color: Color(0xFF747B94)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('怎么玩', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                      SizedBox(height: 14),
                      _Instruction('1', '倒计时结束后，把手指放在点击区附近。'),
                      _Instruction('2', '蓝色时等待，变绿并显示“立即点击”时再点。'),
                      _Instruction('3', '提前点算抢跑，时间内未点算超时。'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('start-training'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => _GamePage(level: _level, record: widget.record),
                  )),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('开始训练'),
                ),
                const SizedBox(height: 16),
                Text(
                  best == null
                      ? '无需登录 · 无需网络 · 现在就能开始'
                      : '本次会话 Level $_level 最佳：'
                          '${best.averageMilliseconds!.round()} ms · '
                          '成功 ${best.successes}/5 轮',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF747B94), fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Text('演示版 0.1.0 · 成绩仅保留到 App 关闭',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9298AD), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GamePage extends StatefulWidget {
  const _GamePage({required this.level, required this.record});

  final int level;
  final BestRecorder record;

  @override
  State<_GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<_GamePage> with WidgetsBindingObserver {
  late final ReactionController _game;
  bool _showingExit = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ReactionController(level: widget.level)..addListener(_onChanged);
    _game.start();
  }

  void _onChanged() {
    if (_game.phase != ReactionPhase.finished || _navigated || !mounted) return;
    _navigated = true;
    final result = _game.summary;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isBest = widget.record(result);
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => _ResultPage(
          result: result,
          isBest: isBest,
          record: widget.record,
        ),
      ));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _game.pause();
  }

  Future<void> _confirmExit() async {
    if (_showingExit || _navigated) return;
    _showingExit = true;
    _game.pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('结束这次训练？'),
        content: const Text('本次尚未完成的训练不会计入最佳成绩。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('继续训练'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('结束训练'),
          ),
        ],
      ),
    );
    _showingExit = false;
    if (!mounted) return;
    if (leave == true) {
      Navigator.of(context).pop();
    } else if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _game.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.removeListener(_onChanged);
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '返回',
            onPressed: _confirmExit,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('反应速度'),
          actions: [
            IconButton(
              tooltip: '暂停训练',
              onPressed: _game.pause,
              icon: const Icon(Icons.pause_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: _game,
                builder: (context, child) {
                  if (_game.phase == ReactionPhase.ready) {
                    final token = _game.signalToken;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _game.signalFramePresented(token);
                    });
                  }
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text('第 ${_game.currentRound} / 5 轮',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        _Tag('Level ${widget.level}'),
                      ]),
                      const SizedBox(height: 18),
                      Row(
                        children: List.generate(ReactionController.roundCount, (index) {
                          final attempt = index < _game.attempts.length
                              ? _game.attempts[index]
                              : null;
                          final color = attempt == null
                              ? const Color(0xFFE1E4F0)
                              : attempt.outcome == AttemptOutcome.success
                                  ? _green
                                  : const Color(0xFFE49B65);
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 7,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 30),
                      _ReactionPad(game: _game),
                      const SizedBox(height: 22),
                      const Text('等待时不要点击，绿色信号出现后再行动。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF747B94))),
                      const SizedBox(height: 18),
                      if (_game.phase == ReactionPhase.paused)
                        FilledButton.icon(
                          key: const Key('continue-training'),
                          onPressed: _game.resume,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('继续训练'),
                        )
                      else
                        const Text('切换到其他应用时会自动暂停',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF9298AD), fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionPad extends StatelessWidget {
  const _ReactionPad({required this.game});

  final ReactionController game;

  @override
  Widget build(BuildContext context) {
    var background = const Color(0xFF29396C);
    var icon = Icons.hourglass_top_rounded;
    var title = '等待信号';
    var subtitle = '先不要点击';
    switch (game.phase) {
      case ReactionPhase.countdown:
        icon = Icons.bolt_rounded;
        title = '${game.countdown}';
        subtitle = '准备开始';
      case ReactionPhase.ready:
        background = _green;
        icon = Icons.touch_app_rounded;
        title = '立即点击';
        subtitle = '就是现在！';
      case ReactionPhase.feedback:
        final attempt = game.lastAttempt!;
        if (attempt.outcome == AttemptOutcome.success) {
          background = const Color(0xFF157A62);
          icon = Icons.check_circle_outline_rounded;
          title = '${attempt.milliseconds} ms';
          subtitle = '捕捉成功';
        } else {
          background = const Color(0xFFAB643C);
          icon = Icons.refresh_rounded;
          title = attempt.outcome == AttemptOutcome.falseStart ? '抢跑了' : '超时了';
          subtitle = attempt.outcome == AttemptOutcome.falseStart
              ? '下一轮等变绿再点击'
              : '下一轮试着更快一点';
        }
      case ReactionPhase.paused:
        background = const Color(0xFF69708C);
        icon = Icons.pause_circle_outline_rounded;
        title = '训练已暂停';
        subtitle = '继续后会重新倒计时';
      case ReactionPhase.finished:
        title = '训练完成';
        subtitle = '正在整理成绩';
        icon = Icons.done_all_rounded;
      case ReactionPhase.idle:
      case ReactionPhase.waiting:
        break;
    }
    return Semantics(
      button: true,
      label: '$title，$subtitle',
      child: GestureDetector(
        key: const Key('reaction-pad'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          final before = game.attempts.length;
          game.tap();
          if (game.attempts.length > before) HapticFeedback.lightImpact();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 310),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withAlpha(220), size: 60),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: game.phase == ReactionPhase.countdown
                    ? const Duration(milliseconds: 150)
                    : Duration.zero,
                child: Text(
                  title,
                  key: ValueKey(title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: game.phase == ReactionPhase.countdown ? 64 : 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.result, required this.isBest, required this.record});

  final ReactionSummary result;
  final bool isBest;
  final BestRecorder record;

  @override
  Widget build(BuildContext context) {
    final average = result.averageMilliseconds;
    return Scaffold(
      appBar: AppBar(title: const Text('本次成绩')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.emoji_events_rounded, color: _purple, size: 64),
                const SizedBox(height: 14),
                Text('训练完成', textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(result.comment, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                _Surface(
                  child: Column(children: [
                    const Text('平均反应时间', style: TextStyle(color: Color(0xFF747B94))),
                    const SizedBox(height: 8),
                    Text(average == null ? '—' : '${average.round()} ms',
                        style: const TextStyle(
                            color: _purple, fontSize: 48, fontWeight: FontWeight.w800)),
                    const Text('仅统计成功轮次', style: TextStyle(color: Color(0xFF9298AD), fontSize: 12)),
                    if (isBest) ...[
                      const SizedBox(height: 16),
                      const _Tag('本次会话 · 同等级新纪录', color: _green),
                    ],
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 28,
                      runSpacing: 18,
                      children: [
                        _Metric('${result.score}', '得分 / 1000'),
                        _Metric('${(result.accuracy * 100).round()}%', '成功率'),
                        _Metric('${result.successes}/5', '成功轮次'),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                _Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('每轮表现 · Level ${result.level}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...result.attempts.asMap().entries.map((entry) {
                        final attempt = entry.value;
                        final success = attempt.outcome == AttemptOutcome.success;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(children: [
                            Icon(success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                color: success ? _green : const Color(0xFFAB643C), size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text('第 ${entry.key + 1} 轮')),
                            Text(success
                                ? '${attempt.milliseconds} ms'
                                : attempt.outcome == AttemptOutcome.falseStart ? '抢跑' : '超时'),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('play-again'),
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                    builder: (_) => _GamePage(level: result.level, record: record),
                  )),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('再练一次'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  key: const Key('back-home'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回首页'),
                ),
                const SizedBox(height: 10),
                const Text('反应时间受手机刷新率和触摸延迟影响。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9298AD), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8EAF3)),
        ),
        child: child,
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color = _purple, this.dark = false});
  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(dark ? 28 : 18),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.number, this.text);
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 13, backgroundColor: const Color(0xFFF0EEFF),
              child: Text(number, style: const TextStyle(color: _purple, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ]),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF747B94), fontSize: 12)),
      ]);
}
