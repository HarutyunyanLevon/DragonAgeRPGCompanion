import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A row of dice. Tap a die to type the number it really shows (for dice
/// rolled at the table). With [dragonLast] the last die is the Dragon Die and
/// gets the accent color.
class DiceRow extends StatelessWidget {
  const DiceRow({
    super.key,
    required this.dice,
    required this.onChanged,
    this.dragonLast = false,
  });

  final List<int> dice;
  final void Function(int index, int value) onChanged;
  final bool dragonLast;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (var i = 0; i < dice.length; i++)
        _Die(
          value: dice[i],
          isDragon: dragonLast && i == dice.length - 1,
          onTap: () async {
            final value = await _askValue(context);
            if (value != null) onChanged(i, value);
          },
        ),
    ]);
  }
}

class _Die extends StatelessWidget {
  const _Die({required this.value, required this.isDragon, required this.onTap});

  final int value;
  final bool isDragon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDragon ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDragon ? colors.onPrimary : null,
              ),
        ),
      ),
    );
  }
}

/// Asks which number a die shows (1-6). Null when cancelled.
Future<int?> _askValue(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.dieValue),
      content: Wrap(spacing: 8, runSpacing: 8, children: [
        for (var n = 1; n <= 6; n++)
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, n),
            child: Text('$n'),
          ),
      ]),
    ),
  );
}
