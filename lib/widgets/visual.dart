import 'dart:math';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../games/shared/challenge.dart';

class VisualTile extends StatelessWidget {
  const VisualTile(this.visual, {super.key, this.size = 64});
  final Visual visual;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _VisualPainter(visual)),
  );
}

class _VisualPainter extends CustomPainter {
  _VisualPainter(this.visual);
  final Visual visual;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = visualColors[visual.color % visualColors.length];
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(visual.turn * pi / 4);
    if (visual.mirrored) canvas.scale(-1, 1);
    final cells = visual.cells;
    if (cells != null && cells.isNotEmpty) {
      final minX = cells.map((p) => p.x).reduce(min),
          minY = cells.map((p) => p.y).reduce(min);
      final width = cells.map((p) => p.x).reduce(max) - minX + 1;
      final height = cells.map((p) => p.y).reduce(max) - minY + 1;
      final unit = min(size.width, size.height) * 0.65 / max(width, height);
      for (final cell in cells) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              (cell.x - minX - width / 2) * unit + 1,
              (cell.y - minY - height / 2) * unit + 1,
              unit - 2,
              unit - 2,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
      }
    } else {
      for (var i = 0; i < visual.count; i++) {
        canvas.save();
        final radius =
            min(size.width, size.height) * (visual.count == 1 ? 0.32 : 0.18);
        if (visual.count > 1) {
          canvas.translate((i - (visual.count - 1) / 2) * radius * 1.55, 0);
        }
        _shape(canvas, paint, radius);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _shape(Canvas canvas, Paint paint, double r) {
    if (visual.shape == 0) {
      canvas.drawCircle(Offset.zero, r, paint);
      return;
    }
    if (visual.shape == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 1.7),
          const Radius.circular(4),
        ),
        paint,
      );
      return;
    }
    if (visual.shape == 5) {
      canvas.drawRect(Rect.fromLTWH(-r, -r / 3, r * 2, r * 2 / 3), paint);
      canvas.drawRect(Rect.fromLTWH(-r / 3, -r, r * 2 / 3, r * 2), paint);
      return;
    }
    final count = visual.shape == 1
        ? 3
        : visual.shape == 3
        ? 4
        : visual.shape == 4
        ? 10
        : 6;
    final path = Path();
    for (var i = 0; i < count; i++) {
      final angle = -pi / 2 + i * 2 * pi / count;
      final length = visual.shape == 4 && i.isOdd ? r * 0.46 : r;
      final point = Offset(cos(angle) * length, sin(angle) * length);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VisualPainter old) => old.visual != visual;
}
