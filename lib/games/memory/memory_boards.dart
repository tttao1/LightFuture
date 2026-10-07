import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/visual.dart';
import '../shared/challenge.dart';

class SequenceBoard extends StatefulWidget {
  const SequenceBoard({
    super.key,
    required this.challenge,
    required this.preview,
    required this.elapsed,
    required this.done,
    required this.feedback,
  });
  final SequenceChallenge challenge;
  final bool preview;
  final Duration elapsed;
  final ValueChanged<RoundOutcome> done;
  final ValueChanged<bool> feedback;
  @override
  State<SequenceBoard> createState() => _SequenceBoardState();
}

class _SequenceBoardState extends State<SequenceBoard> {
  int _step = 0;
  bool _settled = false;
  @override
  Widget build(BuildContext context) {
    final question = widget.challenge;
    final index =
        widget.elapsed.inMilliseconds ~/ question.interval.inMilliseconds;
    final flash =
        widget.elapsed.inMilliseconds % question.interval.inMilliseconds <
        question.interval.inMilliseconds * 0.65;
    final target = widget.preview && index < question.sequence.length && flash
        ? question.sequence[index]
        : -1;
    return Column(
      children: [
        Text(
          widget.preview
              ? '观察序列 ${min(index + 1, question.sequence.length)} / ${question.sequence.length}'
              : '已复现 $_step / ${question.sequence.length}',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: question.size == 4 ? 2 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: List.generate(
            question.size,
            (i) => Material(
              color: i == target ? primary : Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: Key('sequence-$i'),
                borderRadius: BorderRadius.circular(18),
                onTap: widget.preview || _settled
                    ? null
                    : () {
                        final correct = question.sequence[_step] == i;
                        widget.feedback(correct);
                        if (!correct) {
                          _settled = true;
                          widget.done(
                            RoundOutcome(
                              correct: false,
                              detail: question.answerLabel,
                            ),
                          );
                        } else {
                          setState(() => _step++);
                          if (_step == question.sequence.length) {
                            _settled = true;
                            widget.done(const RoundOutcome(correct: true));
                          }
                        }
                      },
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i == target ? Colors.white : primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
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

class PairBoard extends StatefulWidget {
  const PairBoard({
    super.key,
    required this.challenge,
    required this.done,
    required this.progress,
    required this.feedback,
  });
  final PairChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  final void Function(int, int) progress;
  final ValueChanged<bool> feedback;
  @override
  State<PairBoard> createState() => _PairBoardState();
}

class _PairBoardState extends State<PairBoard> {
  final Set<int> _matched = {};
  int? _first, _second;
  int _moves = 0;
  Timer? _hide;
  void _tap(int index) {
    if (_second != null || _matched.contains(index) || _first == index) return;
    if (_first == null) {
      setState(() => _first = index);
      return;
    }
    _moves++;
    final matches =
        widget.challenge.cards[_first!] == widget.challenge.cards[index];
    widget.feedback(matches);
    setState(() => _second = index);
    if (matches) {
      _matched.addAll([_first!, index]);
      _first = null;
      _second = null;
      widget.progress(_matched.length ~/ 2, _moves);
      if (_matched.length == widget.challenge.cards.length) {
        widget.done(
          RoundOutcome(
            correct: true,
            correctCount: _matched.length ~/ 2,
            attempts: _moves,
            quality: (_matched.length / 2 / _moves).clamp(0.0, 1.0),
            detail: '配对尝试 $_moves 次',
          ),
        );
      }
    } else {
      widget.progress(_matched.length ~/ 2, _moves);
      _hide = Timer(const Duration(milliseconds: 650), () {
        if (mounted) {
          setState(() {
            _first = null;
            _second = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TrainingBadge(
        '已找到 ${_matched.length ~/ 2} / ${widget.challenge.cards.length ~/ 2} 对',
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: widget.challenge.cards.length <= 8 ? 3 : 4,
        childAspectRatio: 1.1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: widget.challenge.cards.asMap().entries.map((entry) {
          final open =
              _matched.contains(entry.key) ||
              entry.key == _first ||
              entry.key == _second;
          return Material(
            color: open ? const Color(0xFFEFECFF) : const Color(0xFF34447D),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: Key('card-${entry.key}'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => _tap(entry.key),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: open
                    ? VisualTile(
                        Visual(shape: entry.value % 6, color: entry.value ~/ 6),
                        key: ValueKey('open-${entry.key}'),
                        size: 50,
                      )
                    : const Icon(
                        Icons.question_mark_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}
