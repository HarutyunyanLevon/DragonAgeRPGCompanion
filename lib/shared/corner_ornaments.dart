import 'package:flutter/material.dart';

import 'theme_look.dart';

/// Draws small gold-like corner marks over [child] in themes with
/// [ThemeLook.ornaments] (Chantry). In other themes it is just the child.
class CornerOrnaments extends StatelessWidget {
  const CornerOrnaments({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ThemeLook.of(context).ornaments) return child;

    return CustomPaint(
      foregroundPainter:
          _CornerPainter(Theme.of(context).colorScheme.primary),
      child: child,
    );
  }
}

/// An "L" in each corner with a dot inside it.
class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.color);

  final Color color;

  static const _arm = 12.0; // length of each arm of the L
  static const _inset = 3.0; // distance from the edge

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dot = Paint()..color = color;

    // Each corner: its position and the direction pointing into the box.
    for (final (corner, dx, dy) in [
      (Offset(_inset, _inset), 1.0, 1.0),
      (Offset(size.width - _inset, _inset), -1.0, 1.0),
      (Offset(_inset, size.height - _inset), 1.0, -1.0),
      (Offset(size.width - _inset, size.height - _inset), -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx * _arm, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + dy * _arm),
        line,
      );
      canvas.drawCircle(corner + Offset(dx * 5, dy * 5), 1.5, dot);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
