import 'package:flutter/material.dart';

import '../app/theme.dart';

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE6E9F3)),
    ),
    child: child,
  );
}

class TrainingBadge extends StatelessWidget {
  const TrainingBadge(this.text, {super.key, this.color = primary});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(this.value, this.label, {super.key});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}

class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    ),
  );
}

String formatSeconds(double seconds) => seconds < 60
    ? '${seconds.toStringAsFixed(1)} 秒'
    : '${seconds ~/ 60} 分 ${(seconds % 60).round()} 秒';
