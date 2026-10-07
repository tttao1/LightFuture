import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../shared/challenge.dart';
import 'expression_rules.dart';

class ExpressionBoard extends StatefulWidget {
  const ExpressionBoard({
    super.key,
    required this.challenge,
    required this.done,
  });
  final ExpressionChallenge challenge;
  final ValueChanged<RoundOutcome> done;
  @override
  State<ExpressionBoard> createState() => _ExpressionBoardState();
}

class _ExpressionBoardState extends State<ExpressionBoard> {
  final List<Object> _tokens = [];
  final Set<int> _used = {};
  String get _expression => _tokens
      .map((t) => t is int ? '${widget.challenge.numbers[t]}' : '$t')
      .join();
  void _append(Object token) {
    if (_tokens.length >= 40) return;
    if (token is int && _tokens.isNotEmpty && _tokens.last is int) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两张数字卡片之间需要运算符')));
      return;
    }
    setState(() {
      _tokens.add(token);
      if (token is int) _used.add(token);
    });
  }

  void _undo() {
    if (_tokens.isEmpty) return;
    setState(() {
      final token = _tokens.removeLast();
      if (token is int) _used.remove(token);
    });
  }

  void _submit() {
    if (_used.length != widget.challenge.requiredCards) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('需要使用 ${widget.challenge.requiredCards} 张数字卡片')),
      );
      return;
    }
    try {
      final value = evaluateExpression(_expression);
      widget.done(
        RoundOutcome(
          correct: (value - widget.challenge.target).abs() < 0.00000001,
        ),
      );
    } on FormatException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${error.message}，请调整表达式。')));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TrainingBadge('目标：${widget.challenge.target}'),
      const SizedBox(height: 14),
      Text(
        '使用 ${widget.challenge.requiredCards} 张卡片，每张最多一次',
        style: const TextStyle(color: muted),
      ),
      const SizedBox(height: 16),
      Surface(
        color: const Color(0xFFEFECFF),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            _expression.isEmpty
                ? '点选数字和算符'
                : _expression.replaceAll('*', '×').replaceAll('/', '÷'),
            key: const Key('expression-value'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: widget.challenge.numbers
            .asMap()
            .entries
            .map(
              (entry) => OutlinedButton(
                key: Key('number-card-${entry.key}'),
                onPressed: _used.contains(entry.key)
                    ? null
                    : () => _append(entry.key),
                child: Text(
                  '${entry.value}',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children:
            [
                  '+',
                  '-',
                  if (widget.challenge.allowMultiply) ...['*', '/'],
                  '(',
                  ')',
                ]
                .map(
                  (op) => OutlinedButton(
                    key: Key('operator-$op'),
                    onPressed: () => _append(op),
                    child: Text(
                      op.replaceAll('*', '×').replaceAll('/', '÷'),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: _undo,
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('撤销'),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () => setState(() {
                _tokens.clear();
                _used.clear();
              }),
              child: const Text('清空'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('submit-answer'),
        onPressed: _tokens.isEmpty ? null : _submit,
        child: const Text('提交表达式'),
      ),
    ],
  );
}
