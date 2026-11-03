import 'package:dragon_age_companion/character/derived_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defense = 10 + Dexterity + shield', () {
    expect(defense(dexterity: 2), 12);
    expect(defense(dexterity: 1, shieldBonus: 2), 13);
    expect(defense(dexterity: -1), 9);
  });

  test('shield bonus is capped at +1 without Weapon and Shield Style', () {
    expect(effectiveShieldBonus(3, hasWeaponAndShield: false), 1);
    expect(effectiveShieldBonus(3, hasWeaponAndShield: true), 3);
    expect(effectiveShieldBonus(0, hasWeaponAndShield: false), 0);
  });

  test('speed = race base + Dexterity - armor penalty', () {
    expect(speed(baseSpeed: 10, dexterity: 2), 12);
    expect(speed(baseSpeed: 8, dexterity: 1, armorPenalty: 1), 8);
    expect(speed(baseSpeed: 12, dexterity: 0, armorPenalty: 3), 9);
  });
}
