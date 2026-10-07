import 'dart:math';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/game_catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/keypad.dart';
import '../memory/memory_boards.dart';
import '../attention/selection_boards.dart';
import 'challenge.dart';
import '../logic/sort_board.dart';
import '../calculation/expression_board.dart';
import '../reaction/timing_board.dart';
import '../spatial/spatial_boards.dart';

typedef ProgressCallback = void Function(int hits, int attempts);

class ChallengeBoard extends StatefulWidget {
  const ChallengeBoard({
    super.key,
    required this.challenge,
    required this.preview,
    required this.elapsed,
    required this.done,
    required this.progress,
    required this.feedback,
  });
  final Challenge challenge;
  final bool preview;
  final Duration elapsed;
  final ValueChanged<RoundOutcome> done;
  final ProgressCallback progress;
  final ValueChanged<bool> feedback;
  @override
  State<ChallengeBoard> createState() => _ChallengeBoardState();
}

class _ChallengeBoardState extends State<ChallengeBoard> {
  String _number = '';
  int _nextNumber = 1, _clicks = 0;
  bool? _lastSchulteCorrect;

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    if (challenge is NumberChallenge) {
      if (widget.preview) {
        final stepIndex = challenge.steps.isEmpty
            ? 0
            : min(
                challenge.steps.length,
                widget.elapsed.inMilliseconds ~/
                    max(
                      1,
                      challenge.preview.inMilliseconds ~/
                          (challenge.steps.length + 1),
                    ),
              );
        final display = stepIndex == 0
            ? challenge.display ?? ''
            : challenge.steps[stepIndex - 1];
        return Surface(
          color: const Color(0xFFEEECFF),
          child: SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (challenge.interference) ...[
                  const Positioned(
                    top: 5,
                    left: 4,
                    child: Text(
                      '◇ • △',
                      style: TextStyle(fontSize: 22, color: Color(0xFFB8B2D9)),
                    ),
                  ),
                  const Positioned(
                    bottom: 5,
                    right: 4,
                    child: Text(
                      '△ ◇ •',
                      style: TextStyle(fontSize: 22, color: Color(0xFFB8B2D9)),
                    ),
                  ),
                ],
                Align(
                  alignment: challenge.interference
                      ? Alignment((display.codeUnitAt(0) % 3 - 1) * 0.35, -0.15)
                      : Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: display
                            .split('')
                            .asMap()
                            .entries
                            .map(
                              (entry) => TextSpan(
                                text: entry.value,
                                style: challenge.interference
                                    ? TextStyle(
                                        color: visualColors[entry.key % 6],
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                      key: const Key('memory-preview'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return NumberKeypad(
        value: _number,
        changed: (value) => setState(() => _number = value),
        maxLength: challenge.preview > Duration.zero && challenge.steps.isEmpty
            ? challenge.answer.length
            : 8,
        allowNegative:
            challenge.preview == Duration.zero || challenge.steps.isNotEmpty,
        submit: () => widget.done(
          RoundOutcome(
            correct:
                challenge.preview > Duration.zero && challenge.steps.isEmpty
                ? _number == challenge.answer
                : int.tryParse(_number) == int.tryParse(challenge.answer),
          ),
        ),
      );
    }
    if (challenge is SchulteChallenge) {
      return Column(
        children: [
          TrainingBadge(
            '下一目标：$_nextNumber',
            color: categoryColor(Ability.attention),
          ),
          if (_lastSchulteCorrect != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _lastSchulteCorrect!
                    ? '正确，继续寻找 $_nextNumber'
                    : '刚才点错了，请寻找 $_nextNumber',
                style: TextStyle(
                  color: _lastSchulteCorrect! ? success : Colors.deepOrange,
                ),
              ),
            ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: challenge.size,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: challenge.numbers.asMap().entries.map((entry) {
              final number = entry.value;
              final color = challenge.interference >= 2
                  ? visualColors[(number + entry.key) % 6]
                  : ink;
              return Material(
                color: challenge.interference > 0 && entry.key.isEven
                    ? const Color(0xFFEDEAFB)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: Key('schulte-$number'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _clicks++;
                    final correct = number == _nextNumber;
                    _lastSchulteCorrect = correct;
                    widget.feedback(correct);
                    if (correct) _nextNumber++;
                    widget.progress(_nextNumber - 1, _clicks);
                    if (_nextNumber > challenge.numbers.length) {
                      widget.done(
                        RoundOutcome(
                          correct: true,
                          correctCount: challenge.numbers.length,
                          attempts: _clicks,
                          detail: '误点 ${_clicks - challenge.numbers.length} 次',
                        ),
                      );
                    } else {
                      setState(() {});
                    }
                  },
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }
    if (challenge is GridChallenge) {
      return GridBoard(
        challenge: challenge,
        preview: widget.preview,
        done: widget.done,
      );
    }
    if (challenge is ChoiceChallenge) {
      return ChoiceBoard(challenge: challenge, done: widget.done);
    }
    if (challenge is SequenceChallenge) {
      return SequenceBoard(
        challenge: challenge,
        preview: widget.preview,
        elapsed: widget.elapsed,
        done: widget.done,
        feedback: widget.feedback,
      );
    }
    if (challenge is PairChallenge) {
      return PairBoard(
        challenge: challenge,
        done: widget.done,
        progress: widget.progress,
        feedback: widget.feedback,
      );
    }
    if (challenge is SortChallenge) {
      return SortBoard(challenge: challenge, done: widget.done);
    }
    if (challenge is ExpressionChallenge) {
      return ExpressionBoard(challenge: challenge, done: widget.done);
    }
    if (challenge is TimingChallenge) {
      return TimingBoard(
        challenge: challenge,
        done: widget.done,
        progress: widget.progress,
        feedback: widget.feedback,
      );
    }
    if (challenge is BlockChallenge) {
      return BlockBoard(
        challenge: challenge,
        done: widget.done,
        progress: widget.progress,
        feedback: widget.feedback,
      );
    }
    if (challenge is PathChallenge) {
      return PathBoard(
        challenge: challenge,
        done: widget.done,
        progress: widget.progress,
        feedback: widget.feedback,
      );
    }
    throw StateError('Unsupported challenge: ${challenge.runtimeType}');
  }
}
