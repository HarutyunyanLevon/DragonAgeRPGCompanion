import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/classes.dart';
import '../../rules/models/focus_entry.dart';
import '../../rules/models/gear.dart';
import '../../rules/models/glossary.dart';
import '../../rules/models/specializations.dart';
import '../../rules/models/spell.dart';
import '../../rules/models/stunt.dart';
import '../../rules/models/talents.dart';
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/linked_text.dart';
import '../create/rule_info.dart';
import 'glossary_entries.dart';
import 'glossary_extras.dart';
import 'glossary_notes.dart';
import 'note_dialog.dart';

/// The description of one Glossary entry. Talents, spells, gear... reuse the
/// same info widgets as the Sheet and the wizard; the words in them that name
/// another entry are links (see TextLinks).
class GlossaryEntryView extends ConsumerWidget {
  const GlossaryEntryView({super.key, required this.rules, required this.entry});

  final RulesData rules;
  final GlossaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;

    return switch (entry.category) {
      GlossaryCategory.terms => _term(context, item as GlossaryTerm),
      GlossaryCategory.stunts => _stunt(context, item as Stunt),
      GlossaryCategory.classes => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassInfo(rules: rules, classRules: item as ClassRules),
            ClassPowersByLevel(classRules: item),
          ],
        ),
      GlossaryCategory.weaponGroups =>
        WeaponGroupInfo(rules: rules, group: (item as WeaponGroup).id),
      GlossaryCategory.abilities =>
        AbilityInfo(rules: rules, ability: item as String),
      GlossaryCategory.talents =>
        TalentInfo(rules: rules, talent: item as Talent, degree: null),
      GlossaryCategory.specializations => SpecializationInfo(
          rules: rules, specialization: item as Specialization),
      GlossaryCategory.focuses => FocusInfo(
          rules: rules,
          ability: (item as FocusEntry).ability,
          focus: item.id),
      GlossaryCategory.gear => ItemInfo(
          rules: rules, itemId: (item as CatalogEntry).id, name: item.name),
      GlossaryCategory.spells => SpellInfo(spell: item as Spell),
      GlossaryCategory.notes => _note(context, ref, item as GlossaryNote),
    };
  }

  /// The text of a term, then its table or list if it has one.
  Widget _term(BuildContext context, GlossaryTerm term) {
    final extra = glossaryExtras[term.extra];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LinkedText(term.text),
      if (extra != null) extra(context, rules),
    ]);
  }

  Widget _stunt(BuildContext context, Stunt stunt) {
    final l10n = AppLocalizations.of(context);
    final cost = stunt.variable ? '${stunt.spCost}+' : '${stunt.spCost}';
    return LinkedText('${l10n.stuntCost(cost)}\n${stunt.effect}');
  }

  Widget _note(BuildContext context, WidgetRef ref, GlossaryNote note) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.read(glossaryNotesProvider.notifier);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LinkedText(note.text),
      Wrap(spacing: 8, children: [
        TextButton(
          onPressed: () => showNoteDialog(context, ref, note: note),
          child: Text(l10n.editItem),
        ),
        TextButton(
          onPressed: () async {
            final ok = await confirm(context,
                title: l10n.deleteNoteTitle(note.title),
                confirmLabel: l10n.delete);
            if (ok) await notes.remove(note.id);
          },
          child: Text(l10n.delete),
        ),
      ]),
    ]);
  }
}
