import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/money.dart';
import '../spells/custom_spells.dart';

/// A plain overview of a character. Temporary: the Play tab's widgets will
/// replace it, but the creation wizard also uses it for its last look.
class CharacterSummary extends ConsumerWidget {
  const CharacterSummary({
    super.key,
    required this.character,
    required this.rules,
  });

  final Character character;
  final RulesData rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = character;
    final spells = ref.watch(allSpellsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(l10n.characterLine(displayName(c.race), displayName(c.classId),
              c.level, displayName(c.backgroundId))),
          const SizedBox(height: 8),
          _Line(l10n.health, '${c.health} / ${c.maxHealth}'),
          if (c.maxMana > 0) _Line(l10n.mana, '${c.mana} / ${c.maxMana}'),
          _Line(
            l10n.abilities,
            c.abilities.entries
                .map((e) => '${displayName(e.key)} ${e.value}')
                .join(', '),
          ),
          _Line(
            l10n.focuses,
            c.focuses
                .map((f) => l10n.focusLabel(
                    displayName(f.ability), displayName(f.focus)))
                .join(', '),
          ),
          if (c.traitIds.isNotEmpty)
            _Line(l10n.racialTraits, c.traitIds.map(displayName).join(', ')),
          _Line(
            l10n.talents,
            c.talents.map((t) => rules.talents.talentById(t.id).name).join(', '),
          ),
          if (c.spellIds.isNotEmpty)
            _Line(
              l10n.spells,
              // A homebrew spell that was deleted since is shown by its id.
              c.spellIds
                  .map((id) =>
                      spells.where((s) => s.id == id).firstOrNull?.name ??
                      displayName(id))
                  .join(', '),
            ),
          _Line(l10n.weaponGroups, c.weaponGroups.map(displayName).join(', ')),
          _Line(l10n.languages, c.languages.map(displayName).join(', ')),
          _Line(
            l10n.sectionGear,
            c.inventory
                .map((i) => i.quantity > 1 ? '${i.name} ×${i.quantity}' : i.name)
                .join(', '),
          ),
          _Line(l10n.money, moneyText(l10n, c.copper)),
        ]),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(TextSpan(children: [
        TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: text),
      ])),
    );
  }
}
