import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/form_widgets.dart';
import 'character_draft.dart';
import 'rule_info.dart';

/// The mage's starting spells: a starter set in one tap, or a searchable list
/// (by school) of the spells that need nothing else. Exactly [count] to pick.
class SpellPicker extends ConsumerStatefulWidget {
  const SpellPicker({super.key, required this.count});

  final int count;

  @override
  ConsumerState<SpellPicker> createState() => _SpellPickerState();
}

class _SpellPickerState extends ConsumerState<SpellPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final choices = ref.watch(characterDraftProvider).classChoices;
    final notifier = ref.read(characterDraftProvider.notifier);

    final query = _query.toLowerCase();
    final spells = [
      for (final s in rules.spells)
        if (s.hasNoRequirement && s.name.toLowerCase().contains(query)) s,
    ];
    final schools = {for (final s in spells) s.school}.toList()..sort();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l10n.spellsTitle(widget.count)),
      Text(l10n.starterSets),
      Wrap(spacing: 8, children: [
        for (final set in rules.starterSets)
          ActionChip(
            label: Text(set.name),
            onPressed: () =>
                notifier.setClassChoices(choices.withSpells(set.spells)),
          ),
      ]),
      const SizedBox(height: 8),
      Text(l10n.pickedOf(choices.spells.length, widget.count)),
      TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.searchSpells,
        ),
        onChanged: (text) => setState(() => _query = text),
      ),
      for (final school in schools) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SectionTitle(school),
        ),
        for (final spell in spells.where((s) => s.school == school))
          ExpansionTile(
            // The checkbox picks the spell; the rest of the row opens it.
            leading: Checkbox(
              value: choices.spells.contains(spell.id),
              // Disabled once the limit is reached (unless already picked).
              onChanged: choices.spells.contains(spell.id) ||
                      choices.spells.length < widget.count
                  ? (_) =>
                      notifier.setClassChoices(choices.toggleSpell(spell.id))
                  : null,
            ),
            title: Text(spell.name),
            subtitle: Text('${spell.mana} · ${spell.castTime}'),
            shape: const Border(),
            collapsedShape: const Border(),
            expandedAlignment: Alignment.centerLeft,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [SpellInfo(spell: spell)],
          ),
      ],
    ]);
  }
}
