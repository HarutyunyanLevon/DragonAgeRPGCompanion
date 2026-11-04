import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/stunt.dart';

/// The stunts a roll can buy. Tick the ones you take; a stunt that costs more
/// than the stunt points left is disabled.
class StuntPicker extends StatelessWidget {
  const StuntPicker({
    super.key,
    required this.stunts,
    required this.points,
    required this.picked,
    required this.onToggle,
  });

  final List<Stunt> stunts;

  /// Stunt points of the roll (the Dragon Die).
  final int points;
  final Set<String> picked;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spent = stunts
        .where((s) => picked.contains(s.id))
        .fold(0, (sum, s) => sum + s.spCost);
    final left = points - spent;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.stuntPointsLeft(left, points),
          style: Theme.of(context).textTheme.titleSmall),
      for (final s in stunts)
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: picked.contains(s.id),
          onChanged:
              picked.contains(s.id) || s.spCost <= left ? (_) => onToggle(s.id) : null,
          title: Text('${s.name} (${s.spCost}${s.variable ? '+' : ''} SP)'),
          subtitle: Text(s.effect),
        ),
    ]);
  }
}
