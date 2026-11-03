import 'dart:math';

import '../rules/models/classes.dart';
import '../rules/rules_data.dart';
import '../shared/display_name.dart';
import 'character.dart';

/// The starting equipment rules (book, file 02): everyone gets the basics,
/// the class gives armor and weapons, bow users get arrows and the Weapon
/// and Shield talent gives a shield. Pure functions; they work from the
/// class, weapon groups and talents so the wizard can use them before the
/// [Character] exists.

const _quiverName = 'Quiver';
const _weaponAndShieldStyle = 'weapon-and-shield-style';
const _startingShield = 'medium-shield';

/// Weapons a new character may pick from: those in their weapon groups.
List<String> startingWeaponChoices(List<String> weaponGroups, RulesData rules) =>
    [
      for (final w in rules.weapons)
        if (weaponGroups.contains(w.group)) w.id,
    ];

/// How many weapons the class starts with, limited by what can be picked.
int startingWeaponCount(
  ClassRules classRules,
  List<String> weaponGroups,
  RulesData rules,
) =>
    min(classRules.startingWeapons,
        startingWeaponChoices(weaponGroups, rules).length);

/// The items a new character starts with. Armor, shield and weapons come
/// already equipped. [weaponIds] are the player's picks.
List<InventoryItem> startingItems({
  required ClassRules classRules,
  required List<String> talentIds,
  required List<String> weaponIds,
  required RulesData rules,
}) {
  final weapons = [for (final id in weaponIds) rules.weaponById(id)!];

  InventoryItem fromCatalog(String id, {bool equipped = false}) {
    final entry = rules.catalogEntry(id);
    return InventoryItem(name: entry.name, itemId: id, equipped: equipped);
  }

  // Bow users also get a quiver and 20 arrows (20 bolts for a crossbow).
  final bow = weapons.where((w) => w.group == 'bows').firstOrNull;

  return [
    for (final name in rules.classes.startingGear.everyone)
      InventoryItem(name: capitalize(name)),
    if (classRules.startingExtraItem != null)
      InventoryItem(name: classRules.startingExtraItem!),
    if (classRules.startingArmor != null)
      fromCatalog(classRules.startingArmor!, equipped: true),
    if (talentIds.contains(_weaponAndShieldStyle))
      fromCatalog(_startingShield, equipped: true),
    for (final id in weaponIds) fromCatalog(id, equipped: true),
    if (bow != null) ...[
      const InventoryItem(name: _quiverName),
      fromCatalog(bow.id == 'crossbow' ? 'bolts-20' : 'arrows-20'),
    ],
  ];
}
