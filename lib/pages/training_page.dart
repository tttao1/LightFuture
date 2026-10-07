import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../games/shared/challenge_board.dart';
import '../games/shared/session_controller.dart';
import '../models/game_catalog.dart';
import '../storage/local_store.dart';
import '../widgets/common.dart';
import '../widgets/feedback_service.dart';
import 'result_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({
    super.key,
    required this.game,
    required this.level,
    required this.store,
    this.controller,
  });
  final GameDefinition game;
  final int level;
  final LocalStore store;
  final SessionController? controller;
  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with WidgetsBindingObserver {
  late final SessionController _session;
  final ScrollController _scroll = ScrollController();
  SessionPhase _lastPhase = SessionPhase.countdown;
  bool _navigated = false, _exitDialog = false;
  int _feedbackCount = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session =
        widget.controller ?? SessionController(widget.game, widget.level);
    _session.addListener(_changed);
    _session.start();
  }

  void _changed() {
    if (_lastPhase != _session.phase) {
      _lastPhase = _session.phase;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    if (_session.outcomes.length > _feedbackCount) {
      _feedbackCount = _session.outcomes.length;
      TrainingFeedback.play(
        widget.store,
        correct: _session.outcomes.last.correct,
      );
    }
    if (_session.phase != SessionPhase.finished || _navigated || !mounted) {
      return;
    }
    _navigated = true;
    final result = _session.result;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _session.pause();
  }

  Future<void> _exit() async {
    if (_exitDialog || _navigated) return;
    _exitDialog = true;
    _session.pause();
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
      _session.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_changed);
    _session.dispose();
    _scroll.dispose();
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
            onPressed: _session.pause,
            icon: const Icon(Icons.pause_rounded),
          ),
        ],
      ),
      body: ContentFrame(
        child: AnimatedBuilder(
          animation: _session,
          builder: (context, _) => ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '第 ${_session.round == 0 ? 1 : _session.round} / ${widget.game.rounds} 轮',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TrainingBadge('Level ${widget.level}'),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: _session.outcomes.length / widget.game.rounds,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 20),
              if (_session.phase == SessionPhase.countdown)
                Surface(
                  color: const Color(0xFFEEECFF),
                  child: Column(
                    children: [
                      const SizedBox(height: 35),
                      const Text('准备开始'),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          '${_session.countdown}',
                          key: ValueKey(_session.countdown),
                          style: const TextStyle(
                            color: primary,
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                    ],
                  ),
                )
              else if (_session.phase == SessionPhase.paused) ...[
                const Surface(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 64,
                          color: primary,
                        ),
                        SizedBox(height: 18),
                        Text(
                          '训练已暂停',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('继续后重新倒计时，普通训练保留进度。', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('continue-training'),
                  onPressed: _session.resume,
                  child: const Text('继续训练'),
                ),
              ] else if (_session.phase == SessionPhase.feedback) ...[
                Surface(
                  child: Column(
                    children: [
                      Icon(
                        _session.outcomes.last.correct
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: _session.outcomes.last.correct
                            ? success
                            : Colors.deepOrange,
                        size: 66,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _session.outcomes.last.correct ? '正确！' : '下一轮再试试',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _session.outcomes.last.detail.isEmpty
                            ? _session.challenge!.answerLabel
                            : _session.outcomes.last.detail,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (_session.challenge != null) ...[
                Text(
                  _session.challenge!.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _session.phase == SessionPhase.preview
                      ? '观察阶段 · ${_session.previewRemaining.toStringAsFixed(1)} 秒'
                      : '剩余 ${_session.remaining.ceil()} 秒',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
              ],
              if (_session.challenge != null)
                Offstage(
                  key: const Key('challenge-holder'),
                  offstage:
                      _session.phase != SessionPhase.playing &&
                      _session.phase != SessionPhase.preview,
                  child: TickerMode(
                    enabled:
                        _session.phase == SessionPhase.playing ||
                        _session.phase == SessionPhase.preview,
                    child: IgnorePointer(
                      ignoring: _session.phase != SessionPhase.playing,
                      child: ChallengeBoard(
                        key: ValueKey(_session.revision),
                        challenge: _session.challenge!,
                        preview: _session.phase == SessionPhase.preview,
                        elapsed: _session.phaseElapsed,
                        done: _session.settle,
                        progress: _session.progress,
                        feedback: (correct) => TrainingFeedback.play(
                          widget.store,
                          correct: correct,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                '退出或切换应用时暂停 · 所有训练完全离线',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
