import 'package:flutter/material.dart';

/// Health or Mana as a plate: a colored edge on the left, the label, a big
/// number "46 / 54" and a thin bar. [control] (the - and + buttons) goes under
/// the bar. Tapping the plate calls [onTap].
class VitalPlate extends StatelessWidget {
  const VitalPlate({
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

  /// The edge and the bar.
  final Color color;
  final Widget? control;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 8)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              child: Text(label.toUpperCase(), style: text.labelSmall),
            ),
            FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$current', style: text.headlineMedium),
                  Text(' / $max', style: text.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: max <= 0 ? 0 : (current / max).clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: colors.surface,
              borderRadius: BorderRadius.zero,
            ),
            if (control != null) Align(alignment: Alignment.centerRight, child: control),
          ]),
        ),
      ),
    );
  }
}
