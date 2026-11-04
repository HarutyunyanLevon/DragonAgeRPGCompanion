import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// "25 + Constitution 2 + d6", a Roll button, and 1-6 chips to enter a d6
/// that was rolled at the table.
class DieRow extends StatelessWidget {
  const DieRow({
    super.key,
    required this.label,
    required this.base,
    required this.ability,
    required this.score,
    required this.die,
    required this.onChanged,
  });

  final String label;
  final int base;
  final String ability;
  final int score;
  final int? die;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formula = l10n.formula(base, ability, score, '${die ?? 'd6'}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(die == null
              ? formula
              : l10n.formulaTotal(formula, base + score + die!)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.casino_outlined),
                label: Text(l10n.rollDie),
                onPressed: () => onChanged(Random().nextInt(6) + 1),
              ),
              for (var value = 1; value <= 6; value++)
                ChoiceChip(
                  label: Text('$value'),
                  selected: die == value,
                  onSelected: (_) => onChanged(value),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}
