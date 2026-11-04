import '../rules/models/spell.dart';
import '../rules/rules_data.dart';
import '../rules/slug.dart';
import 'character.dart';
import 'test_roll.dart';

/// Spellcasting rules (book, file 08) as pure functions: who can cast, what a
/// spell costs, the casting bonus, requirements and mishaps.

/// Only classes with mana (mages) learn and cast spells.
bool canCast(Character character, RulesData rules) =>
    rules.classes.classById(character.classId).mana != null;

/// The mana cost of a spell as written: "7 MP" (fixed), "1-3 MP" (you choose)
/// or "20+ MP" (at least).
class ManaCost {
  const ManaCost(this.min, this.max);

  final int min;

  /// Null: no upper limit ("20+ MP").
  final int? max;

  bool get isFixed => min == max;
}

/// Reads "7 MP", "1-3 MP" or "20+ MP". Null when the text is none of those.
ManaCost? parseManaCost(String text) {
  final match =
      RegExp(r'^\s*(\d+)\s*(?:-\s*(\d+)|(\+))?\s*MP\s*$').firstMatch(text);
  if (match == null) return null;
  final min = int.parse(match.group(1)!);
  if (match.group(3) != null) return ManaCost(min, null);
  return ManaCost(min, int.parse(match.group(2) ?? match.group(1)!));
}

/// Mana added to every spell by the worn armor (magic.json "armorStrain").
int armorStrain(Character character, RulesData rules) {
  for (final item in character.inventory) {
    final strain = rules.magic.armorStrain[item.itemId];
    if (item.equipped && strain != null) return strain;
  }
  return 0;
}

/// An ability score plus the focus bonus (+2, +3 if taken twice) when the
/// character has that focus.
int testBonus(Character character, String ability, String focus) {
  final owned = character.focuses
      .where((f) => f.ability == ability && f.focus == focus)
      .firstOrNull;
  return character.ability(ability) + (owned?.bonus ?? 0);
}

/// Added to the casting roll: Magic plus the focus of the spell's school.
int castingBonus(Character character, Spell spell) =>
    testBonus(character, 'magic', slug(spell.school));

/// 10 + Magic + school focus. Targets roll against it.
int spellpower(Character character, Spell spell) =>
    10 + castingBonus(character, spell);

/// The spell's target number (10 when the text is not a plain number).
int spellTn(Spell spell) => int.tryParse(spell.tn.trim()) ?? 10;

bool meetsRequirement(Character character, SpellRequirement requirement) =>
    switch (requirement.type) {
      'spell' => character.spellIds.contains(requirement.id),
      'talent' => character.talents
          .any((t) => t.id == requirement.id && t.degree >= requirement.degree),
      'specialization' => character.specializations
          .any((s) => s.id == requirement.id && s.degree >= requirement.degree),
      _ => false,
    };

/// The requirements of [spell] the character does not meet yet.
List<SpellRequirement> unmetRequirements(Character character, Spell spell) => [
      for (final r in spell.requires)
        if (!meetsRequirement(character, r)) r,
    ];

/// A mishap only happens to a spell with a requirement, when the casting
/// roll fails and its Dragon Die shows 1.
bool causesMishap(Spell spell, TestRoll roll, {required bool success}) =>
    !success && roll.dragonDie == 1 && !spell.hasNoRequirement;
