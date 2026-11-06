import 'package:flutter/material.dart';

/// Health or Mana as a stained-glass vial (Chantry theme): the label, then a
/// rounded vial filled with a glowing gradient up to the current value, dark
/// "leading" lines across it and the number "46 / 54" on top. [control] (the
/// - and + buttons) goes under the vial. Tapping the vial calls [onTap].
class GlassVial extends StatelessWidget {
  const GlassVial({
    super.key,
    required this.label,
    required this.current,
    required this.max,
    required this.color,
    this.control,
    this.onTap,
  });

  final String label;
  final int current;
  final int max;

  /// The glass color.
  final Color color;
  final Widget? control;
  final VoidCallback? onTap;

  static const _height = 34.0;
  static const _panes = 8; // leading lines make this many panes

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fraction = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    final shape = BorderRadius.circular(_height / 2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(label.toUpperCase(), style: text.labelSmall),
          ),
        ),
        InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Container(
            height: _height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: shape,
              border: Border.all(color: colors.outline, width: 2),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.55), color],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _LeadingPainter(_panes, colors.surface),
                ),
              ),
              FittedBox(
                child: Text(
                  '$current / $max',
                  style: text.titleMedium?.copyWith(
                    shadows: [Shadow(color: colors.surface, blurRadius: 4)],
                  ),
                ),
              ),
            ]),
          ),
        ),
        if (control != null) Align(alignment: Alignment.centerRight, child: control),
      ]),
    );
  }
}

/// Dark vertical lines that split the vial into panes, like the lead between
/// pieces of stained glass.
class _LeadingPainter extends CustomPainter {
  const _LeadingPainter(this.panes, this.color);

  final int panes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var i = 1; i < panes; i++) {
      final x = size.width * i / panes;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_LeadingPainter old) =>
      old.panes != panes || old.color != color;
}
