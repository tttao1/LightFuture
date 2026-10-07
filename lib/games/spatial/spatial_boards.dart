import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/visual.dart';
import '../shared/challenge.dart';
import 'spatial_rules.dart';

class BlockBoard extends StatefulWidget {
  const BlockBoard({
    super.key,
    required this.challenge,
    required this.done,
    required this.progress,
    required this.feedback,
  });
  final BlockChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  final void Function(int, int) progress;
  final ValueChanged<bool> feedback;
  @override
  State<BlockBoard> createState() => _BlockBoardState();
}

class _BlockBoardState extends State<BlockBoard> {
  late final List<int> _turns = List.filled(widget.challenge.pieces.length, 0);
  final Map<int, List<int>> _placed = {};
  int? _selected;
  int _errors = 0;
  bool _finished = false;
  Map<int, int> get _owners => {
    for (final piece in _placed.entries)
      for (final cell in piece.value) cell: piece.key,
  };
  void _place(int piece, int anchor) {
    if (_finished) return;
    final size = widget.challenge.size;
    final shape = rotateCells(widget.challenge.pieces[piece], _turns[piece]);
    final cells = shape
        .map((p) => Cell(anchor % size + p.x, anchor ~/ size + p.y))
        .toList();
    final owners = _owners;
    final valid = cells.every(
      (p) =>
          p.x >= 0 &&
          p.x < size &&
          p.y >= 0 &&
          p.y < size &&
          (!owners.containsKey(p.y * size + p.x) ||
              owners[p.y * size + p.x] == piece),
    );
    if (!valid) {
      _errors++;
      widget.feedback(false);
      widget.progress(owners.length, owners.length + _errors);
      return;
    }
    setState(() {
      _placed[piece] = cells.map((p) => p.y * size + p.x).toList();
      _selected = piece;
    });
    widget.feedback(true);
    final filled = _owners.length;
    widget.progress(filled, filled + _errors);
    if (filled == size * size) {
      _finished = true;
      widget.done(
        RoundOutcome(
          correct: true,
          correctCount: filled,
          attempts: filled + _errors,
          quality: (filled / (filled + _errors)).clamp(0.0, 1.0),
          detail: '全部拼块放置成功，错误放置 $_errors 次',
        ),
      );
    }
  }

  void _retrieve() {
    if (_selected == null) return;
    setState(() => _placed.remove(_selected));
    widget.progress(_owners.length, _owners.length + _errors);
  }

  Widget _piece(int index) {
    final cells = rotateCells(widget.challenge.pieces[index], _turns[index]);
    final tile = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _selected == index ? const Color(0xFFE5E0FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selected == index ? primary : const Color(0xFFDDE1ED),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VisualTile(Visual(cells: cells, color: index), size: 66),
          Text(
            '拼块 ${index + 1}${_placed.containsKey(index) ? ' ✓' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
    return GestureDetector(
      key: Key('piece-$index'),
      onTap: () => setState(() => _selected = index),
      child: LongPressDraggable<int>(
        data: index,
        delay: const Duration(milliseconds: 200),
        onDragStarted: () => setState(() => _selected = index),
        feedback: Material(
          color: Colors.transparent,
          child: VisualTile(Visual(cells: cells, color: index), size: 100),
        ),
        child: tile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owners = _owners, size = widget.challenge.size;
    return Column(
      children: [
        TrainingBadge('已覆盖 ${owners.length} / ${size * size} 格'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: size,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: List.generate(
            size * size,
            (index) => DragTarget<int>(
              onAcceptWithDetails: (data) => _place(data.data, index),
              builder: (context, candidates, rejected) => Material(
                color: owners.containsKey(index)
                    ? visualColors[owners[index]! % 6].withAlpha(170)
                    : candidates.isNotEmpty
                    ? const Color(0xFFE5E0FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: Key('block-$index'),
                  onTap: _selected == null
                      ? null
                      : () => _place(_selected!, index),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      owners.containsKey(index) ? '${owners[index]! + 1}' : '·',
                      style: TextStyle(
                        color: owners.containsKey(index) ? Colors.white : muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(widget.challenge.pieces.length, _piece),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('rotate-piece'),
                onPressed: _selected == null || _placed.containsKey(_selected)
                    ? null
                    : () => setState(
                        () => _turns[_selected!] = (_turns[_selected!] + 1) % 4,
                      ),
                icon: const Icon(Icons.rotate_right_rounded),
                label: const Text('旋转'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _selected == null || !_placed.containsKey(_selected)
                    ? null
                    : _retrieve,
                child: const Text('取回所选'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '长按拖放，或先选拼块再点锚点格子。\n锚点是拼块包围框的左上角；调整时先取回。',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}

class PathBoard extends StatefulWidget {
  const PathBoard({
    super.key,
    required this.challenge,
    required this.done,
    required this.progress,
    required this.feedback,
  });
  final PathChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  final void Function(int, int) progress;
  final ValueChanged<bool> feedback;
  @override
  State<PathBoard> createState() => _PathBoardState();
}

class _PathBoardState extends State<PathBoard> {
  final List<int> _route = [0];
  int _errors = 0;
  bool _finished = false;
  void _move(int index, {bool drag = false}) {
    if (_finished || index == _route.last) return;
    if (_route.length > 1 && index == _route[_route.length - 2]) {
      setState(() => _route.removeLast());
      return;
    }
    if (!neighbors(_route.last, widget.challenge.size).contains(index) ||
        widget.challenge.obstacles.contains(index)) {
      if (!drag) {
        _errors++;
        widget.feedback(false);
      }
      return;
    }
    setState(() => _route.add(index));
    widget.feedback(true);
    widget.progress(_route.length - 1, _route.length - 1 + _errors);
    if (index == widget.challenge.size * widget.challenge.size - 1) {
      _finished = true;
      widget.done(
        RoundOutcome(
          correct: true,
          correctCount: _route.length - 1,
          attempts: _route.length - 1 + _errors,
          quality: (widget.challenge.shortest / (_route.length - 1)).clamp(
            0.0,
            1.0,
          ),
          detail:
              '走了 ${_route.length - 1} 步，最短路线 ${widget.challenge.shortest} 步',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.challenge.size;
    return Column(
      children: [
        TrainingBadge('当前走了 ${_route.length - 1} 步'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) => GestureDetector(
            onPanStart: (details) => _move(
              (details.localPosition.dy / (box.maxWidth / size)).floor().clamp(
                        0,
                        size - 1,
                      ) *
                      size +
                  (details.localPosition.dx / (box.maxWidth / size))
                      .floor()
                      .clamp(0, size - 1),
              drag: true,
            ),
            onPanUpdate: (details) => _move(
              (details.localPosition.dy / (box.maxWidth / size)).floor().clamp(
                        0,
                        size - 1,
                      ) *
                      size +
                  (details.localPosition.dx / (box.maxWidth / size))
                      .floor()
                      .clamp(0, size - 1),
              drag: true,
            ),
            child: GridView.count(
              crossAxisCount: size,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: List.generate(size * size, (index) {
                final blocked = widget.challenge.obstacles.contains(index),
                    visited = _route.contains(index),
                    current = _route.last == index;
                return Material(
                  color: blocked
                      ? const Color(0xFF68738C)
                      : current
                      ? primary
                      : visited
                      ? const Color(0xFFDCD7FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    key: Key('path-$index'),
                    onTap: () => _move(index),
                    borderRadius: BorderRadius.circular(9),
                    child: Center(
                      child: Icon(
                        blocked
                            ? Icons.close_rounded
                            : index == size * size - 1
                            ? Icons.flag_rounded
                            : current
                            ? Icons.circle_rounded
                            : Icons.circle_outlined,
                        color: blocked || current
                            ? Colors.white
                            : index == size * size - 1
                            ? success
                            : const Color(0xFFCAD0E1),
                        size: 24,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 18,
          children: [
            TextButton.icon(
              onPressed: _route.length <= 1
                  ? null
                  : () {
                      setState(() => _route.removeLast());
                      widget.progress(
                        _route.length - 1,
                        _route.length - 1 + _errors,
                      );
                    },
              icon: const Icon(Icons.undo_rounded),
              label: const Text('退一步'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _route.removeRange(1, _route.length));
                widget.progress(0, _errors);
              },
              child: const Text('重新走'),
            ),
          ],
        ),
        const Text(
          '沿相邻格滑动，也可以逐格点击；旗帜是终点。',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}
