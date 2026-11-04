import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/magic.dart';
import '../../character/providers.dart';
import '../../character/test_roll.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../roll/dice_row.dart';

/// Shown under a failed casting roll whose Dragon Die is 1: the Willpower
/// (Self-Discipline) test against the spell's TN, then what it means. [cost]
/// is the mana the spell took (with armor strain).
class MishapHelper extends ConsumerStatefulWidget {
  const MishapHelper({
    super.key,
    required this.rules,
    required this.cost,
    required this.tn,
  });

  final RulesData rules;
  final int cost;
  final int tn;

  @override
  ConsumerState<MishapHelper> createState() => _MishapHelperState();
}

class _MishapHelperState extends ConsumerState<MishapHelper> {
  final _random = Random();
  TestRoll? _save; // the Willpower test
  bool _effectApplied = false; // a mana / health loss was taken

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
    final character = ref.watch(selectedCharacterProvider).requireValue!;
    final save = _save;
    final cost = widget.cost;

    final title = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(l10n.mishapTitle, style: Theme.of(context).textTheme.titleMedium),
    );

    if (save == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title,
        Text(l10n.mishapIntro(widget.tn)),
        FilledButton.tonal(
          onPressed: () => setState(() => _save = TestRoll.roll(_random)),
          child: Text(l10n.rollWillpower),
        ),
      ]);
    }

    final bonus = testBonus(character, 'willpower', 'self-discipline');
    final saved = save.total(bonus) >= widget.tn;
    final mishap = widget.rules.magic.mishapFor(save.dragonDie);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title,
      DiceRow(
        dice: save.dice,
        dragonLast: true,
        onChanged: (i, value) => setState(() {
          _save = save.withDie(i, value);
          _effectApplied = false;
        }),
      ),
      Text(l10n.willpowerLine(save.total(bonus), widget.tn)),
      if (saved) ...[
        Text(l10n.mishapProne),
        _effectButton(l10n, l10n.payToStand(cost), () => _lose(mana: cost)),
      ] else ...[
        Text('${mishap.name}: ${mishap.effect}'),
        if (mishap.die == 1)
          _effectButton(l10n, l10n.loseMana(2 * cost), () => _lose(mana: 2 * cost)),
        if (mishap.die == 2)
          _effectButton(
              l10n, l10n.loseHealth(2 * cost), () => _lose(health: 2 * cost)),
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
