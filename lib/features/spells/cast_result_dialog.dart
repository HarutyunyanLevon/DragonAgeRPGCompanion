import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/magic.dart';
import '../../character/providers.dart';
import '../../character/test_roll.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/spell.dart';
import '../../rules/rules_data.dart';

/// The result of a casting roll: dice, total against the TN, the stunts the
/// stunt points buy, and the mishap helper. Re-roll never charges mana again;
/// Undo gives the mana of this casting back.
class CastResultDialog extends ConsumerStatefulWidget {
  const CastResultDialog({
    super.key,
    required this.spell,
    required this.rules,
    required this.base,
    required this.strain,
    required this.spent,
  });

  final Spell spell;
  final RulesData rules;

  /// The spell's mana cost and the armor strain added to it.
  final int base;
  final int strain;

  /// The mana that was really taken (less than base + strain when mana ran out).
  final int spent;

  @override
  ConsumerState<CastResultDialog> createState() => _CastResultDialogState();
}

class _CastResultDialogState extends ConsumerState<CastResultDialog> {
  final _random = Random();
  late TestRoll _roll = TestRoll.roll(_random);
  TestRoll? _saveRoll; // the Willpower test of a mishap
  bool _effectApplied = false; // a mishap's mana / health loss was taken

  int get _cost => widget.base + widget.strain;

  void _reroll() => setState(() {
        _roll = TestRoll.roll(_random);
        _saveRoll = null;
        _effectApplied = false;
      });

  Future<void> _undo() async {
    final character = ref.read(selectedCharacterProvider).requireValue!;
    await ref.read(charactersProvider.notifier).save(character.copyWith(
        mana: min(character.maxMana, character.mana + widget.spent)));
    if (mounted) Navigator.pop(context);
  }

  /// Takes mana and / or Health away (never below 0).
  Future<void> _lose({int mana = 0, int health = 0}) async {
    final character = ref.read(selectedCharacterProvider).requireValue!;
    await ref.read(charactersProvider.notifier).save(character.copyWith(
          mana: max(0, character.mana - mana),
          health: max(0, character.health - health),
        ));
    setState(() => _effectApplied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spell = widget.spell;
    final character = ref.watch(selectedCharacterProvider).requireValue!;

    final bonus = castingBonus(character, spell);
    final tn = spellTn(spell);
    final success = _roll.total(bonus) >= tn;
    final stuntPoints = success && _roll.hasDoubles ? _roll.dragonDie : 0;
    final stunts = [
      for (final s in widget.rules.magic.standardStunts)
        if (s.spCost <= stuntPoints) s,
    ];

    return AlertDialog(
      title: Text(spell.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.strain == 0
                ? l10n.manaSpent(widget.spent)
                : l10n.manaSpentStrain(widget.spent, widget.base, widget.strain)),
            const SizedBox(height: 8),
            Text(l10n.diceLine(_roll.dice[0], _roll.dice[1], _roll.dragonDie)),
            Text(l10n.castTotal(_roll.sum, bonus, _roll.total(bonus))),
            Text(
              success ? l10n.castSuccess(tn) : l10n.castFail(tn),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(l10n.spellpowerLine(spellpower(character, spell))),
            if (stuntPoints > 0) ...[
              const SizedBox(height: 8),
              Text(l10n.stuntPoints(stuntPoints),
                  style: Theme.of(context).textTheme.titleSmall),
              for (final s in stunts)
                Text(l10n.stuntLine(
                    s.name, '${s.spCost}${s.variable ? '+' : ''}', s.effect)),
            ],
            if (causesMishap(spell, _roll, success: success))
              _mishap(l10n, tn),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _undo, child: Text(l10n.undo)),
        TextButton(onPressed: _reroll, child: Text(l10n.reroll)),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  /// The mishap helper: the Willpower (Self-Discipline) test against the
  /// spell's TN, then what it means.
  Widget _mishap(AppLocalizations l10n, int tn) {
    final character = ref.read(selectedCharacterProvider).requireValue!;
    final save = _saveRoll;
    final title = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(l10n.mishapTitle,
          style: Theme.of(context).textTheme.titleMedium),
    );

    if (save == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title,
        Text(l10n.mishapIntro(tn)),
        FilledButton.tonal(
          onPressed: () => setState(() => _saveRoll = TestRoll.roll(_random)),
          child: Text(l10n.rollWillpower),
        ),
      ]);
    }

    final bonus = testBonus(character, 'willpower', 'self-discipline');
    final saved = save.total(bonus) >= tn;
    final mishap = widget.rules.magic.mishapFor(save.dragonDie);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title,
      Text(l10n.diceLine(save.dice[0], save.dice[1], save.dragonDie)),
      Text(l10n.willpowerLine(save.total(bonus), tn)),
      if (saved) ...[
        Text(l10n.mishapProne),
        _effectButton(l10n, l10n.payToStand(_cost), () => _lose(mana: _cost)),
      ] else ...[
        Text('${mishap.name}: ${mishap.effect}'),
        if (mishap.die == 1)
          _effectButton(
              l10n, l10n.loseMana(2 * _cost), () => _lose(mana: 2 * _cost)),
        if (mishap.die == 2)
          _effectButton(
              l10n, l10n.loseHealth(2 * _cost), () => _lose(health: 2 * _cost)),
      ],
    ]);
  }

  /// One button that takes a loss; after it is used it shows "Applied".
  Widget _effectButton(
      AppLocalizations l10n, String label, VoidCallback onPressed) {
    if (_effectApplied) return Text(l10n.applied);
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
