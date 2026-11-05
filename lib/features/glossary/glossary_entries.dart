import '../../rules/models/glossary.dart';
import '../../rules/models/spell.dart';
import '../../rules/models/stunt.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';

/// The kinds of entry the Glossary tab lists (one filter chip each), in the
/// order of the list.
enum GlossaryCategory {
  terms,
  stunts,
  classes,
  weaponGroups,
  abilities,
  talents,
  specializations,
  focuses,
  gear,
  spells,
  notes,
}

/// One row of the Glossary: where it comes from, how it is grouped and what a
/// search looks at. [item] is the thing itself (a GlossaryTerm, Talent,
/// Spell...); the entry view casts it back by [category].
class GlossaryEntry {
  const GlossaryEntry({
    required this.category,
    required this.title,
    required this.item,
    this.group = '',
    this.texts = const [],
    this.linkNames = const [],
  });

  final GlossaryCategory category;
  final String title;
  final Object item;

  /// Small heading above a run of entries of one category ("Combat").
  final String group;

  /// What the search looks at, besides the title.
  final List<String> texts;

  /// The words in other texts that link to this entry. Empty: nothing links
  /// here automatically (focus and gear names are everyday words).
  final List<String> linkNames;

  List<String> get searchTexts => [title, ...texts];

  /// Tells entries apart between rebuilds (the list is built again on every
  /// change, so an entry is remembered by this, not by identity).
  String get key => '${category.name}/$group/$title';
}

/// Every entry in the order the tab shows them: category by category, and
/// inside a category grouped (terms by topic, focuses by ability...).
List<GlossaryEntry> buildGlossary({
  required RulesData rules,
  required List<Spell> spells,
  required List<GlossaryNote> notes,
}) {
  GlossaryEntry stunt(String group, Stunt s) => GlossaryEntry(
        category: GlossaryCategory.stunts,
        title: s.name,
        item: s,
        group: group,
        texts: [s.effect],
        linkNames: [s.name],
      );

  return [
    for (final t in rules.glossaryTerms)
      GlossaryEntry(
        category: GlossaryCategory.terms,
        title: t.name,
        item: t,
        group: t.topic,
        texts: [t.text],
        linkNames: t.autoLink ? t.linkNames : const [],
      ),
    for (final s in rules.combatStunts) stunt('Combat', s),
    for (final s in rules.explorationStunts) stunt('Exploration', s),
    for (final s in rules.roleplayingStunts) stunt('Roleplaying', s),
    for (final c in rules.classes.classes)
      GlossaryEntry(
        category: GlossaryCategory.classes,
        title: c.name,
        item: c,
        linkNames: [c.name],
      ),
    for (final g in rules.weaponGroups)
      GlossaryEntry(
        category: GlossaryCategory.weaponGroups,
        title: displayName(g.id),
        item: g,
        linkNames: [displayName(g.id)],
      ),
    for (final ability in rules.backgrounds.abilities)
      GlossaryEntry(
        category: GlossaryCategory.abilities,
        title: displayName(ability),
        item: ability,
        texts: [rules.abilityDescriptions[ability] ?? ''],
        linkNames: [displayName(ability)],
      ),
    for (final t in rules.talents.talents)
      GlossaryEntry(
        category: GlossaryCategory.talents,
        title: t.name,
        item: t,
        texts: [
          t.degrees.novice,
          t.degrees.journeyman,
          t.degrees.master,
          ...t.notes,
        ],
        linkNames: [t.name],
      ),
    for (final s in rules.specializations.specializations)
      GlossaryEntry(
        category: GlossaryCategory.specializations,
        title: s.name,
        item: s,
        group: displayName(s.classId),
        texts: [
          s.degrees.novice,
          s.degrees.journeyman,
          s.degrees.master,
          ...s.notes,
        ],
        linkNames: [s.name],
      ),
    for (final f in rules.focuses)
      GlossaryEntry(
        category: GlossaryCategory.focuses,
        title: f.name,
        item: f,
        group: displayName(f.ability),
      ),
    for (final item in rules.catalog)
      GlossaryEntry(
        category: GlossaryCategory.gear,
        title: item.name,
        item: item,
        group: displayName(item.category),
        texts: [item.note ?? ''],
      ),
    for (final s in spells)
      GlossaryEntry(
        category: GlossaryCategory.spells,
        title: s.name,
        item: s,
        group: s.school,
        texts: [s.description],
        linkNames: [s.name],
      ),
    for (final n in notes)
      GlossaryEntry(
        category: GlossaryCategory.notes,
        title: n.title,
        item: n,
        texts: [n.text],
      ),
  ];
}
