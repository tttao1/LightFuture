import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/visual.dart';
import '../shared/challenge.dart';

class GridBoard extends StatefulWidget {
  const GridBoard({
    super.key,
    required this.challenge,
    required this.preview,
    required this.done,
  });
  final GridChallenge challenge;
  final bool preview;
  final ValueChanged<RoundOutcome> done;
  @override
  State<GridBoard> createState() => _GridBoardState();
}

class _GridBoardState extends State<GridBoard> {
  final Set<int> _selected = {};
  Widget _grid(
    List<Visual> visuals, {
    required bool reference,
  }) => GridView.count(
    crossAxisCount: widget.challenge.columns,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 5,
    mainAxisSpacing: 5,
    children: visuals.asMap().entries.map((entry) {
      final observed =
          widget.preview && widget.challenge.targets.contains(entry.key);
      final selected = !reference && _selected.contains(entry.key),
          hidden = widget.challenge.hideTargets;
      return Material(
        color: observed || selected ? const Color(0xFFDCD7FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: reference ? null : Key('grid-${entry.key}'),
          borderRadius: BorderRadius.circular(12),
          onTap: reference || widget.preview
              ? null
              : () => setState(() {
                  if (!_selected.add(entry.key)) _selected.remove(entry.key);
                }),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hidden)
                Text(
                  '${entry.key + 1}',
                  style: TextStyle(
                    color: observed || selected ? primary : muted,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                VisualTile(entry.value, size: 45),
              if (selected)
                const Positioned(
                  right: 3,
                  top: 3,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: primary,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList(),
  );
  @override
  Widget build(BuildContext context) {
    final question = widget.challenge;
    return Column(
      children: [
        if (question.target != null) ...[
          const Text('目标样例', style: TextStyle(color: muted)),
          VisualTile(question.target!, size: 64),
          const SizedBox(height: 10),
        ],
        if (question.reference != null) ...[
          const Text('原图', style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          _grid(question.reference!, reference: true),
          const SizedBox(height: 14),
          const Text('在下方选出变化的位置'),
          const SizedBox(height: 8),
        ],
        _grid(question.visuals, reference: false),
        const SizedBox(height: 16),
        if (!widget.preview) ...[
          Text(
            '已选中 ${_selected.length} 个',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('submit-answer'),
            onPressed: _selected.isEmpty
                ? null
                : () => widget.done(
                    RoundOutcome(
                      correct:
                          _selected.length == question.targets.length &&
                          _selected.containsAll(question.targets),
                    ),
                  ),
            child: const Text('提交选择'),
          ),
        ],
      ],
    );
  }
}

class ChoiceBoard extends StatelessWidget {
  const ChoiceBoard({super.key, required this.challenge, required this.done});
  final ChoiceChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (challenge.word != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            challenge.word!,
            style: TextStyle(
              fontSize: 50,
              color: visualColors[challenge.wordColor],
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      if (challenge.reference != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(child: VisualTile(challenge.reference!, size: 115)),
            ),
            if (challenge.comparison != null) ...[
              const Icon(Icons.compare_arrows_rounded, color: muted),
              Expanded(
                child: Center(
                  child: VisualTile(challenge.comparison!, size: 115),
                ),
              ),
            ],
          ],
        ),
      if (challenge.sequence.isNotEmpty)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ...challenge.sequence.map((visual) => VisualTile(visual, size: 50)),
            const SizedBox(
              width: 45,
              height: 50,
              child: Center(
                child: Text(
                  '?',
                  style: TextStyle(fontSize: 32, color: primary),
                ),
              ),
            ),
          ],
        ),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: challenge.options.any((o) => o.visual != null)
            ? 0.92
            : 1.65,
        children: challenge.options
            .asMap()
            .entries
            .map(
              (entry) => OutlinedButton(
                key: Key('choice-${entry.key}'),
                onPressed: () => done(
                  RoundOutcome(correct: entry.key == challenge.correctIndex),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (entry.value.visual != null)
                      Flexible(
                        child: VisualTile(entry.value.visual!, size: 88),
                      ),
                    Text(
                      entry.value.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}
