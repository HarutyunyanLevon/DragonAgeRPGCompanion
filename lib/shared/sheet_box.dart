import 'package:flutter/material.dart';

/// An outlined box like the ones on the paper character sheet: an optional
/// shaded [header] on top, then the [children] (usually InfoRows).
class SheetBox extends StatelessWidget {
  const SheetBox({super.key, this.header, required this.children});

  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (header != null)
          Material(color: colors.surfaceContainerHighest, child: header),
        ...children,
      ]),
    );
  }
}
