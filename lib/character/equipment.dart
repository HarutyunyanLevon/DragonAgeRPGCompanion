import '../rules/models/gear.dart';
import '../rules/rules_data.dart';
import 'character.dart';
import 'derived_stats.dart';

/// What the inventory means for the character: which items can be equipped,
/// and Defense, Speed, Armor Rating and weapon numbers. Pure functions.

// Rule values from gear.json ("weaponRules") and the talents file.
const _untrainedAttackPenalty = 2;
const _belowMinStrengthDamage = '1d6-1';
const _armorTraining = 'armor-training';
const _weaponAndShieldStyle = 'weapon-and-shield-style';

bool _isArmor(RulesData rules, InventoryItem item) =>
    rules.armorById(item.itemId) != null;

bool _isShield(RulesData rules, InventoryItem item) =>
    rules.shieldById(item.itemId) != null;

/// Armor, shields and weapons can be equipped; everything else cannot.
bool canEquip(RulesData rules, InventoryItem item) =>
    _isArmor(rules, item) ||
    _isShield(rules, item) ||
    rules.weaponById(item.itemId) != null;

/// Equips or unequips the item at [index]. Only one armor and one shield can
/// be equipped, so equipping a second one unequips the first.
List<InventoryItem> toggleEquipped(
    List<InventoryItem> inventory, int index, RulesData rules) {
  final item = inventory[index];
  final equip = !item.equipped;

  bool sameSlot(InventoryItem other) =>
      (_isArmor(rules, item) && _isArmor(rules, other)) ||
      (_isShield(rules, item) && _isShield(rules, other));

  return [
    for (var i = 0; i < inventory.length; i++)
      if (i == index)
        inventory[i].copyWith(equipped: equip)
      else if (equip && sameSlot(inventory[i]))
        inventory[i].copyWith(equipped: false)
      else
        inventory[i],
  ];
}

/// Adds one more of an item, or a new row when it is not in the inventory yet.
/// Custom items (no id) are always new rows.
List<InventoryItem> addItem(List<InventoryItem> inventory, InventoryItem item) {
  final index = item.itemId == null
      ? -1
      : inventory.indexWhere((i) => i.itemId == item.itemId);
  if (index == -1) return [...inventory, item];
  return [
    for (var i = 0; i < inventory.length; i++)
      i == index
          ? inventory[i].copyWith(quantity: inventory[i].quantity + 1)
          : inventory[i],
  ];
}

/// Defense, Speed and Armor Rating, with the parts they are made of (the
/// Sheet shows the parts in the description).
class CombatNumbers {
  const CombatNumbers({
    required this.defense,
    required this.speed,
    required this.armorRating,
    required this.dexterityForDefense,
    required this.shieldBonus,
    required this.armorPenalty,
    required this.baseSpeed,
    required this.dexterity,
  });

  final int defense;
  final int speed;
  final int armorRating;

  /// Dexterity minus the armor penalty when the character lacks Armor Training.
  final int dexterityForDefense;

  /// The shield bonus that counts (capped at +1 without the talent).
  final int shieldBonus;
  final int armorPenalty;
  final int baseSpeed; // by race
  final int dexterity;
}

/// Defense, Speed and Armor Rating from the equipped armor and shield.
/// Without Armor Training the armor penalty also lowers Dexterity (Defense).
/// Without Weapon and Shield Style a shield gives at most +1.
CombatNumbers combatNumbers(Character character, RulesData rules) {
  final worn = [for (final i in character.inventory) if (i.equipped) i];
  final armor =
      worn.map((i) => rules.armorById(i.itemId)).nonNulls.firstOrNull;
  final shield =
      worn.map((i) => rules.shieldById(i.itemId)).nonNulls.firstOrNull;

  bool hasTalent(String id) => character.talents.any((t) => t.id == id);
  final penalty = armor?.armorPenalty ?? 0;
  final dexterity = character.ability('dexterity');
  final dexterityForDefense =
      dexterity - (hasTalent(_armorTraining) ? 0 : penalty);
  final shieldBonus = effectiveShieldBonus(
    shield?.defenseBonus ?? 0,
    hasWeaponAndShield: hasTalent(_weaponAndShieldStyle),
  );
  final baseSpeed = rules.classes.speed.baseByRace[character.race] ?? 10;

  return CombatNumbers(
    defense: defense(dexterity: dexterityForDefense, shieldBonus: shieldBonus),
    speed: speed(
        baseSpeed: baseSpeed, dexterity: dexterity, armorPenalty: penalty),
    armorRating: armor?.armorRating ?? 0,
    dexterityForDefense: dexterityForDefense,
    shieldBonus: shieldBonus,
    armorPenalty: penalty,
    baseSpeed: baseSpeed,
    dexterity: dexterity,
  );
}

class WeaponNumbers {
  const WeaponNumbers({
    required this.attack,
    required this.damage,
    required this.trained,
  });

  final int attack; // bonus added to the attack roll
  final String damage; // "2d6+3"
  final bool trained; // false: the character lacks the weapon group
}

/// Attack bonus = attack ability + weapon focus (+2 / +3) - 2 if untrained.
/// Damage = weapon dice + damage ability. An untrained weapon does half
/// damage; the screen only warns about that, it does not halve the text.
WeaponNumbers weaponNumbers(
    Character character, Weapon weapon, RulesData rules) {
  final group = rules.weaponGroupById(weapon.group);
  final trained = character.weaponGroups.contains(weapon.group);

  final focus = character.focuses
      .where((f) => rules.focuses
          .any((e) => e.id == f.focus && e.weaponGroup == weapon.group))
      .firstOrNull;
  final strongEnough = character.ability('strength') >= weapon.minStrength;

  return WeaponNumbers(
    attack: character.ability(group.attackAbility) +
        (focus?.bonus ?? 0) -
        (trained ? 0 : _untrainedAttackPenalty),
    damage: addToDice(
      strongEnough ? weapon.damage : _belowMinStrengthDamage,
      character.ability(group.damageAbility),
    ),
    trained: trained,
  );
}

/// "2d6" + 3 -> "2d6+3", "1d6+2" + 1 -> "1d6+3". Text that is not dice is
/// returned unchanged.
String addToDice(String dice, int bonus) {
  final match = RegExp(r'^(\d+d\d+)([+-]\d+)?$').firstMatch(dice);
  if (match == null) return dice;
  final flat = int.parse(match.group(2) ?? '0') + bonus;
  if (flat == 0) return match.group(1)!;
  return '${match.group(1)}${flat > 0 ? '+' : ''}$flat';
}
