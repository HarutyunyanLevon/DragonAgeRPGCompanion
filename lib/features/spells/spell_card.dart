import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/magic.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/spell.dart';
import '../../rules/rules_data.dart';
import '../create/rule_info.dart';
import 'spell_actions.dart';

/// Everything about one spell, and for a mage the buttons to learn or forget
/// it (and to delete it, if it is homebrew).
class SpellCard extends ConsumerWidget {
  const SpellCard({
    super.key,
    required this.character,
    required this.rules,
    required this.spell,
  });

  final Character character;
  final RulesData rules;
  final Spell spell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mage = canCast(character, rules);
    final known = character.spellIds.contains(spell.id);
    final unmet = unmetRequirements(character, spell);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SpellInfo(spell: spell),
      if (spell.homebrew)
        Text(l10n.homebrew, style: const TextStyle(fontStyle: FontStyle.italic)),
      if (mage && !known && unmet.isNotEmpty)
        Text(
          l10n.requirementsMissing(
              unmet.map((r) => requirementLabel(l10n, rules, r)).join(', ')),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (mage)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 8, children: [
            if (known)
              OutlinedButton(
                onPressed: () => forgetSpell(context, ref, character, spell),
                child: Text(l10n.forgetSpell),
              )
            else
              FilledButton.tonal(
                onPressed: () =>
                    learnSpell(context, ref, character, rules, spell),
                child: Text(l10n.learnSpell),
              ),
            if (spell.homebrew)
              TextButton(
                onPressed: () =>
                    deleteHomebrewSpell(context, ref, character, spell),
                child: Text(l10n.deleteSpell),
              ),
          ]),
        ),
    ]);
  }
}
