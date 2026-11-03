import 'dart:math';

/// Values worked out from the character sheet. Pure functions: easy to test.

/// Defense = 10 + Dexterity + shield bonus.
int defense({required int dexterity, int shieldBonus = 0}) =>
    10 + dexterity + shieldBonus;

/// Without the Weapon and Shield Style talent a shield gives at most +1.
int effectiveShieldBonus(int shieldBonus, {required bool hasWeaponAndShield}) =>
    hasWeaponAndShield ? shieldBonus : min(shieldBonus, 1);

/// Speed = race base + Dexterity - armor penalty.
int speed({
  required int baseSpeed,
  required int dexterity,
  int armorPenalty = 0,
}) =>
    baseSpeed + dexterity - armorPenalty;
