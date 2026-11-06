import 'package:flutter/material.dart';

/// One row of a list that opens a description when tapped (several rows can
/// be open). The wizard's pickers and the Sheet are built from these.
///
/// [leading] is a control that works on its own (a checkbox, an icon button).
/// [value] is shown at the right end of the title, e.g. a bonus or a price.
/// [actions] are buttons under the subtitle (the Attack / Damage of a weapon).
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.value,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? value;
  final Widget? actions;

  /// The description shown when the row is open.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: leading,
      title: value == null
          ? Text(title)
          : Row(children: [
              Expanded(child: Text(title)),
              Text(value!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
            ]),
      subtitle: _subtitle(),
      shape: const Border(),
      collapsedShape: const Border(),
      expandedAlignment: Alignment.centerLeft,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [child],
    );
  }

  Widget? _subtitle() {
    if (actions == null) return subtitle == null ? null : Text(subtitle!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (subtitle != null) Text(subtitle!),
      Padding(padding: const EdgeInsets.only(top: 6), child: actions),
    ]);
  }
}
