import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../games/reaction_controller.dart';
import '../models/game_catalog.dart';
import '../models/training_result.dart';
import '../storage/local_store.dart';
import '../widgets/common.dart';
import '../widgets/feedback_service.dart';
import 'result_page.dart';

class ReactionTrainingPage extends StatefulWidget {
  const ReactionTrainingPage({
    super.key,
    required this.game,
    required this.level,
    required this.store,
  });
  final GameDefinition game;
  final int level;
  final LocalStore store;
  @override
  State<ReactionTrainingPage> createState() => _ReactionTrainingPageState();
}

class _ReactionTrainingPageState extends State<ReactionTrainingPage>
    with WidgetsBindingObserver {
  late final ReactionController _game;
  final Stopwatch _elapsed = Stopwatch();
  bool _navigated = false, _exitDialog = false;
  int _feedbackCount = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ReactionController(level: widget.level)..addListener(_changed);
    _elapsed.start();
    _game.start();
  }

  void _changed() {
    if (_game.attempts.length > _feedbackCount) {
      _feedbackCount = _game.attempts.length;
      TrainingFeedback.play(
        widget.store,
        correct: _game.lastAttempt!.outcome == AttemptOutcome.success,
      );
    }
    if (_game.phase != ReactionPhase.finished || _navigated || !mounted) return;
    _navigated = true;
    _elapsed.stop();
    final summary = _game.summary;
    final result = TrainingResult(
      game: GameId.reactionSpeed,
      level: widget.level,
      score: summary.score,
      correct: summary.successes,
      attempts: 5,
      seconds: _elapsed.elapsedMilliseconds / 1000,
      completed: true,
      metrics: {
        '平均反应毫秒': summary.averageMilliseconds?.toStringAsFixed(0) ?? '—',
        '成功轮次': '${summary.successes}/5',
        '抢跑次数': '${summary.falseStarts}',
        '超时次数': '${summary.timeouts}',
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isBest = widget.store.record(result);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ResultPage(result: result, isBest: isBest, store: widget.store),
        ),
      );
    });
  }

  void _pause() {
    _elapsed.stop();
    _game.pause();
  }

  void _resume() {
    _elapsed.start();
    _game.resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  Future<void> _exit() async {
    if (_exitDialog || _navigated) return;
    _exitDialog = true;
    _pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束这次训练？'),
        content: const Text('未完成的训练不会保存到成绩记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续训练'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('结束训练'),
          ),
        ],
      ),
    );
    _exitDialog = false;
    if (!mounted) return;
    if (leave == true) {
      Navigator.of(context).pop();
    } else if (WidgetsBinding.instance.lifecycleState ==
        AppLifecycleState.resumed) {
      _resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.removeListener(_changed);
    _game.dispose();
    _elapsed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        leading: IconButton(
          tooltip: '返回',
          onPressed: _exit,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: '暂停训练',
            onPressed: _pause,
            icon: const Icon(Icons.pause_rounded),
          ),
        ],
      ),
      body: ContentFrame(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            if (_game.phase == ReactionPhase.ready) {
              final token = _game.signalToken;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _game.signalFramePresented(token);
              });
            }
            final phase = _game.phase;
            final ready = phase == ReactionPhase.ready,
                paused = phase == ReactionPhase.paused,
                feedback = phase == ReactionPhase.feedback;
            final correct =
                _game.lastAttempt?.outcome == AttemptOutcome.success;
            final title = phase == ReactionPhase.countdown
                ? '${_game.countdown}'
                : ready
                ? '立即点击'
                : paused
                ? '训练已暂停'
                : feedback
                ? correct
                      ? '${_game.lastAttempt!.milliseconds} ms'
                      : _game.lastAttempt!.outcome == AttemptOutcome.falseStart
                      ? '抢跑了'
                      : '超时了'
                : '等待信号';
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '第 ${_game.currentRound} / 5 轮',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TrainingBadge('Level ${widget.level}'),
                  ],
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _game.attempts.length / 5,
                  minHeight: 6,
                ),
                const SizedBox(height: 26),
                Semantics(
                  button: true,
                  label: title,
                  child: GestureDetector(
                    key: const Key('reaction-pad'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _game.tap(),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 320),
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: ready
                            ? success
                            : feedback && !correct
                            ? const Color(0xFFAB643C)
                            : const Color(0xFF29396C),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 35),
                          Icon(
                            ready
                                ? Icons.touch_app_rounded
                                : paused
                                ? Icons.pause_circle_outline_rounded
                                : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 26),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: phase == ReactionPhase.countdown
                                  ? 64
                                  : 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            phase == ReactionPhase.countdown
                                ? '准备开始'
                                : ready
                                ? '就是现在！'
                                : paused
                                ? '继续后会重新倒计时'
                                : '绿色信号出现后再点击',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (paused)
                  FilledButton(
                    key: const Key('continue-training'),
                    onPressed: _resume,
                    child: const Text('继续训练'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  '随机等待，避免预判 · 成绩以本设备训练比较为准',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
