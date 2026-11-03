import '../../rules/models/backgrounds.dart';
import '../../rules/models/classes.dart';

/// Step 4a: what the class lets the player pick at level 1. Immutable: every
/// change returns a new object. Everything is stored as rules ids.
class ClassChoices {
  const ClassChoices({
    this.weaponGroups = const [],
    this.talents = const [],
    this.spells = const [],
  });

  final List<String> weaponGroups;
  final List<String> talents;
  final List<String> spells;

  ClassChoices withWeaponGroups(List<String> weaponGroups) => ClassChoices(
        weaponGroups: weaponGroups,
        talents: talents,
        spells: spells,
      );

  ClassChoices withTalents(List<String> talents) => ClassChoices(
        weaponGroups: weaponGroups,
        talents: talents,
        spells: spells,
      );

  ClassChoices toggleSpell(String id) => ClassChoices(
        weaponGroups: weaponGroups,
        talents: talents,
        spells: _toggled(spells, id),
      );

  /// Replaces all spells (a starter set).
  ClassChoices withSpells(List<String> spells) => ClassChoices(
        weaponGroups: weaponGroups,
        talents: talents,
        spells: spells,
      );

  /// Every pick the class asks for has been made.
  bool isComplete(ClassRules classRules) =>
      weaponGroups.length == classRules.weaponGroups.pick &&
      talents.length == classRules.startingTalents.pick &&
      spells.length == classRules.startingSpells;
}

/// Adds [id], or removes it when it is in the list already.
List<String> _toggled(List<String> list, String id) => list.contains(id)
    ? [for (final other in list) if (other != id) other]
    : [...list, id];

/// The weapon groups a class may still pick: its list without the groups the
/// background's table results already gave ([backgroundResults]).
List<String> availableWeaponGroups(
  ClassRules classRules,
  List<TableResult> backgroundResults,
) {
  final taken = {
    for (final r in backgroundResults)
      if (r.type == 'weaponGroup') r.group,
  };
  return [
    for (final group in classRules.weaponGroups.pickFrom)
      if (!taken.contains(group)) group,
  ];
}
