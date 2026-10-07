import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../shared/challenge.dart';

class TimingBoard extends StatefulWidget {
  const TimingBoard({
    super.key,
    required this.challenge,
    required this.done,
    required this.progress,
    required this.feedback,
  });
  final TimingChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  final void Function(int, int) progress;
  final ValueChanged<bool> feedback;
  @override
  State<TimingBoard> createState() => _TimingBoardState();
}

class _TimingBoardState extends State<TimingBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _elapsed = 0, _signalAt = -1, _hits = 0, _extra = 0;
  double _quality = 0;
  bool _finished = false;
  final Set<int> _processed = {};
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _finish(RoundOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    widget.done(outcome);
  }

  void _tick(Duration elapsed) {
    if (_finished) return;
    _elapsed = elapsed.inMilliseconds;
    final question = widget.challenge;
    if (question.kind == TimingKind.rhythm) {
      for (var i = 0; i < question.beats.length; i++) {
        if (!_processed.contains(i) &&
            _elapsed > question.beats[i] + question.tolerance) {
          _processed.add(i);
        }
      }
      widget.progress(_hits, max(1, _processed.length + _extra));
      if (_elapsed > question.beats.last + question.tolerance + 250) {
        _finish(
          RoundOutcome(
            correct: _hits > 0,
            correctCount: _hits,
            attempts: question.beats.length + _extra,
            quality: _hits == 0 ? 0 : _quality / _hits,
            detail: '命中 $_hits / ${question.beats.length} 拍，额外点击 $_extra 次',
          ),
        );
        return;
      }
    } else {
      if (_signalAt < 0 && _elapsed >= question.delay.inMilliseconds) {
        _signalAt = _elapsed;
      }
      if (_signalAt >= 0 &&
          _elapsed - _signalAt >= question.window.inMilliseconds) {
        final keptStill =
            question.kind == TimingKind.inhibition && !question.shouldTap;
        _finish(
          RoundOutcome(
            correct: keptStill,
            detail: keptStill ? '成功保持不点击' : '目标出现后没有及时点击',
          ),
        );
        return;
      }
    }
    if (mounted) setState(() {});
  }

  void _tap([int? index]) {
    if (_finished) return;
    final question = widget.challenge;
    if (question.kind == TimingKind.rhythm) {
      final candidates =
          List.generate(
            question.beats.length,
            (i) => i,
          ).where((i) => !_processed.contains(i)).toList()..sort(
            (a, b) => (_elapsed - question.beats[a]).abs().compareTo(
              (_elapsed - question.beats[b]).abs(),
            ),
          );
      final nearest = candidates.isEmpty ? null : candidates.first;
      final correct =
          nearest != null &&
          (_elapsed - question.beats[nearest]).abs() <= question.tolerance;
      if (correct) {
        _processed.add(nearest);
        _hits++;
        _quality +=
            1 - (_elapsed - question.beats[nearest]).abs() / question.tolerance;
      } else {
        _extra++;
      }
      widget.feedback(correct);
      setState(() {});
      return;
    }
    if (_signalAt < 0) {
      _finish(const RoundOutcome(correct: false, detail: '提前点击了，等信号出现后再行动'));
      return;
    }
    final correct = question.kind == TimingKind.inhibition
        ? question.shouldTap
        : index == question.targetIndex;
    final within = _elapsed - _signalAt < question.window.inMilliseconds;
    _finish(
      RoundOutcome(
        correct: correct && within,
        quality: correct && within
            ? (1 - (_elapsed - _signalAt) / question.window.inMilliseconds)
                  .clamp(0.0, 1.0)
            : 0,
        detail: !within
            ? '响应时间已过'
            : correct
            ? '捕捉成功'
            : '该信号不需要点击，或点击了其他位置',
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.challenge;
    if (question.kind == TimingKind.rhythm) {
      final upcoming = List.generate(question.beats.length, (i) => i)
          .firstWhere(
            (i) => !_processed.contains(i),
            orElse: () => question.beats.length - 1,
          );
      final position = ((_elapsed - question.beats[upcoming] + 800) / 1600)
          .clamp(0.0, 1.0);
      return Column(
        children: [
          TrainingBadge('命中 $_hits / ${question.beats.length} 拍'),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(painter: _RhythmPainter(position)),
          ),
          const SizedBox(height: 18),
          const Text('圆点到达中央竖线时点击', style: TextStyle(color: muted)),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('rhythm-tap'),
            onPressed: _tap,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text('点击节拍'),
            ),
          ),
        ],
      );
    }
    final visible = _signalAt >= 0;
    if (question.kind == TimingKind.inhibition) {
      return GestureDetector(
        key: const Key('inhibition-tap'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tap(),
        child: Surface(
          color: visible
              ? question.shouldTap
                    ? const Color(0xFFE0F5EC)
                    : const Color(0xFFFDE5DF)
              : const Color(0xFFEEECFF),
          child: SizedBox(
            height: 270,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  !visible
                      ? Icons.hourglass_empty_rounded
                      : question.shouldTap
                      ? Icons.circle_rounded
                      : Icons.close_rounded,
                  size: 85,
                  color: !visible
                      ? primary
                      : question.shouldTap
                      ? success
                      : Colors.deepOrange,
                ),
                const SizedBox(height: 20),
                Text(
                  !visible
                      ? '等待符号'
                      : question.shouldTap
                      ? '圆形：点击'
                      : '叉形：不要点',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final count = question.columns == 4
        ? 12
        : question.columns * question.columns;
    return Column(
      children: [
        Text(
          visible ? '点击带闪电的格子' : '等待目标出现',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: question.columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: List.generate(
            count,
            (i) => Material(
              color: visible && i == question.targetIndex
                  ? const Color(0xFFFFE7CE)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: Key('flash-$i'),
                onTap: () => _tap(i),
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Icon(
                    visible && i == question.targetIndex
                        ? Icons.bolt_rounded
                        : Icons.circle_outlined,
                    size: 36,
                    color: visible && i == question.targetIndex
                        ? Colors.deepOrange
                        : const Color(0xFFBCC2D9),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RhythmPainter extends CustomPainter {
  const _RhythmPainter(this.position);
  final double position;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFD9DDED)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(18, size.height / 2),
      Offset(size.width - 18, size.height / 2),
      line,
    );
    final zone = Paint()..color = success.withAlpha(35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 38,
          height: 86,
        ),
        const Radius.circular(12),
      ),
      zone,
    );
    canvas.drawLine(
      Offset(size.width / 2, 15),
      Offset(size.width / 2, size.height - 15),
      Paint()
        ..color = success
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(18 + (size.width - 36) * position, size.height / 2),
      14,
      Paint()..color = primary,
    );
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter old) => old.position != position;
}
