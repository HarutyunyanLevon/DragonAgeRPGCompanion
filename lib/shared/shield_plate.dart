import 'package:flutter/material.dart';

import 'theme_look.dart';

/// A plate with a number over its label: Defense, Armor, Speed in themes that
/// draw them as [StatShape.shield] (Warrior) or [StatShape.arch] (Chantry).
/// [selected] (its description is open) fills it with the accent color.
/// Without an [onTap] it is not tappable.
class ShieldPlate extends StatelessWidget {
  const ShieldPlate({
    super.key,
    required this.shape,
    required this.label,
    required this.value,
    this.selected = false,
    this.onTap,
  });

  final StatShape shape;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fill = selected ? colors.primary : colors.secondary;
    final ink = selected ? colors.onPrimary : colors.onSecondary;
    final arch = shape == StatShape.arch;

    return ClipPath(
      clipper: arch ? const _ArchClipper() : const _ShieldClipper(),
      child: Material(
        color: fill,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // Room where the shape cuts the corners: the point of the shield
            // at the bottom, the curve of the arch at the top.
            padding: arch
                ? const EdgeInsets.fromLTRB(4, 20, 4, 8)
                : const EdgeInsets.fromLTRB(4, 8, 4, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FittedBox(
                child: Text(value,
                    style: text.headlineSmall?.copyWith(color: ink)),
              ),
              FittedBox(
                child: Text(label.toUpperCase(),
                    style: text.labelSmall?.copyWith(color: ink)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Flat top, straight sides, a point at the bottom.
class _ShieldClipper extends CustomClipper<Path> {
  const _ShieldClipper();

  static const _sideHeight = 0.78; // where the sides start to slope

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * _sideHeight)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(0, size.height * _sideHeight)
    ..close();

  @override
  bool shouldReclip(_ShieldClipper oldClipper) => false;
}

/// Straight sides, flat bottom, a pointed gothic arch on top.
class _ArchClipper extends CustomClipper<Path> {
  const _ArchClipper();

  static const _shoulder = 0.38; // height of the arch, as part of the plate

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h)
      ..lineTo(0, h * _shoulder)
      ..quadraticBezierTo(0, h * 0.08, w / 2, 0)
      ..quadraticBezierTo(w, h * 0.08, w, h * _shoulder)
      ..lineTo(w, h)
      ..close();
  }

  @override
  bool shouldReclip(_ArchClipper oldClipper) => false;
}
