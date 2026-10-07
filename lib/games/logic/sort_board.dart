import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../shared/challenge.dart';

class SortBoard extends StatefulWidget {
  const SortBoard({super.key, required this.challenge, required this.done});
  final SortChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  @override
  State<SortBoard> createState() => _SortBoardState();
}

class _SortBoardState extends State<SortBoard> {
  late final List<int> _numbers = List.of(widget.challenge.numbers);
  void _swap(int a, int b) => setState(() {
    final value = _numbers[a];
    _numbers[a] = _numbers[b];
    _numbers[b] = value;
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('拖动右侧把手，或用箭头调整位置', style: TextStyle(color: muted)),
      const SizedBox(height: 12),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _numbers.length,
        onReorder: (oldIndex, newIndex) => setState(() {
          if (newIndex > oldIndex) newIndex--;
          final number = _numbers.removeAt(oldIndex);
          _numbers.insert(newIndex, number);
        }),
        itemBuilder: (context, index) => Card(
          key: ValueKey(_numbers[index]),
          child: ListTile(
            title: Text(
              '${_numbers[index]}',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('sort-up-$index'),
                  onPressed: index == 0 ? null : () => _swap(index, index - 1),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton(
        key: const Key('submit-answer'),
        onPressed: () => widget.done(
          RoundOutcome(
            correct: List.generate(
              _numbers.length,
              (i) => _numbers[i] == widget.challenge.answer[i],
            ).every((b) => b),
          ),
        ),
        child: const Text('提交排序'),
      ),
    ],
  );
}
