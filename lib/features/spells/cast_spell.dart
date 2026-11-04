import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/magic.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/spell.dart';
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import 'cast_result_dialog.dart';

/// Casts [spell]: asks how much mana to spend when the cost can vary, adds
/// the armor strain, takes the mana (strict rules: with too little mana it
/// asks "Proceed anyway?" and mana stops at 0), then shows the casting roll.
Future<void> castSpell(BuildContext context, WidgetRef ref, Character character,
    RulesData rules, Spell spell) async {
  final l10n = AppLocalizations.of(context);
  final printed = parseManaCost(spell.mana) ?? const ManaCost(0, null);

  final base = printed.isFixed ? printed.min : await _askCost(context, spell, printed);
  if (base == null || !context.mounted) return;

  final strain = armorStrain(character, rules);
  final cost = base + strain;
  if (cost > character.mana) {
    final ok = await confirm(
      context,
      title: l10n.notEnoughMana,
      body: l10n.notEnoughManaBody(cost, character.mana),
      confirmLabel: l10n.proceedAnyway,
    );
    if (!ok || !context.mounted) return;
  }

  final spent = min(cost, character.mana);
  await ref
      .read(charactersProvider.notifier)
      .save(character.copyWith(mana: character.mana - spent));
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (_) => CastResultDialog(
      spell: spell,
      rules: rules,
      base: base,
      strain: strain,
      spent: spent,
    ),
  );
}

Future<int?> _askCost(BuildContext context, Spell spell, ManaCost range) {
  return showDialog<int>(
    context: context,
    builder: (_) => _ManaCostDialog(spell: spell, range: range),
  );
}

/// A stepper for the mana of a spell with a variable cost ("1-3 MP", "20+ MP").
class _ManaCostDialog extends StatefulWidget {
  const _ManaCostDialog({required this.spell, required this.range});

  final Spell spell;
  final ManaCost range;

  @override
  State<_ManaCostDialog> createState() => _ManaCostDialogState();
}

class _ManaCostDialogState extends State<_ManaCostDialog> {
  late int _mana = widget.range.min;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final limit = widget.range.max; // null: no upper limit

    return AlertDialog(
      title: Text(widget.spell.name),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l10n.manaCostHelp(widget.spell.mana)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed:
                _mana > widget.range.min ? () => setState(() => _mana--) : null,
          ),
          Text(l10n.manaAmount(_mana),
              style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed:
                limit == null || _mana < limit ? () => setState(() => _mana++) : null,
          ),
        ]),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _mana),
          child: Text(l10n.cast),
        ),
      ],
    );
  }
}
