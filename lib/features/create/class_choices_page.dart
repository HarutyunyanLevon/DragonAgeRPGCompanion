import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/row_picker.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import 'character_draft.dart';
import 'class_choices.dart';
import 'rule_info.dart';
import 'spell_picker.dart';
import 'starting_gear_page.dart';

/// Wizard step 4a of 4: what the class lets you pick. Only the sections the
/// class has are shown (warrior: weapon groups, talents; rogue: a talent;
/// mage: a talent and spells).
class ClassChoicesPage extends ConsumerWidget {
  const ClassChoicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final draft = ref.watch(characterDraftProvider);
    final notifier = ref.read(characterDraftProvider.notifier);

    final classRules = rules.classes.classById(draft.classId!);
    final choices = draft.classChoices;
    final groups = availableWeaponGroups(
        classRules, draft.benefits.results(draft.benefitFacts(rules)));
    final talents = classRules.startingTalents;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(4, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(l10n.stepClassChoices,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (classRules.weaponGroups.pick > 0)
          _PickSection(
            title: l10n.weaponGroupsTitle(classRules.weaponGroups.pick),
            known: l10n.alreadyKnown(
                classRules.weaponGroups.fixed.map(displayName).join(', ')),
            options: [for (final g in groups) (g, displayName(g))],
            picked: choices.weaponGroups,
            limit: classRules.weaponGroups.pick,
            onChange: (ids) =>
                notifier.setClassChoices(choices.withWeaponGroups(ids)),
            describe: (id) => WeaponGroupInfo(rules: rules, group: id),
          ),
        _PickSection(
          title: l10n.talentsTitle(talents.pick),
          known: talents.fixed.isEmpty
              ? null
              : l10n.alsoGranted(talents.fixed
                  .map((id) => rules.talents.talentById(id).name)
                  .join(', ')),
          options: [
            for (final id in talents.pickFrom)
              (id, rules.talents.talentById(id).name),
          ],
          picked: choices.talents,
          limit: talents.pick,
          onChange: (ids) => notifier.setClassChoices(choices.withTalents(ids)),
          describe: (id) =>
              TalentInfo(rules: rules, talent: rules.talents.talentById(id)),
        ),
        if (classRules.startingSpells > 0)
          SpellPicker(count: classRules.startingSpells),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: choices.isComplete(classRules)
              ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const StartingGearPage(),
                  ))
              : null,
          child: Text(l10n.next),
        ),
      ]),
    );
  }
}

/// A title, an optional "already have" line, rows to pick [limit] of (each opens
/// its description) and how many are picked.
class _PickSection extends StatelessWidget {
  const _PickSection({
    required this.title,
    required this.known,
    required this.options,
    required this.picked,
    required this.limit,
    required this.onChange,
    required this.describe,
  });

  final String title;
  final String? known;

  /// (id, label) of every choice.
  final List<(String, String)> options;
  final List<String> picked;
  final int limit;
  final ValueChanged<List<String>> onChange;
  final Widget Function(String id) describe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionTitle(title),
        if (known != null) ...[Text(known!), const SizedBox(height: 8)],
        RowPicker(
          options: options,
          picked: picked,
          limit: limit,
          onChange: onChange,
          describe: describe,
        ),
        const SizedBox(height: 4),
        Text(l10n.pickedOf(picked.length, limit)),
      ]),
    );
  }
}
