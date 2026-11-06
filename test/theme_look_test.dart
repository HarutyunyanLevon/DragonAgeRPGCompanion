import 'package:dragon_age_companion/character/equipment.dart';
import 'package:dragon_age_companion/features/roll/weapon_roll.dart';
import 'package:dragon_age_companion/shared/theme_look.dart';
import 'package:dragon_age_companion/shared/theme_specs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only warrior and chantry have shapes so far', () {
    for (final id in AppThemeId.values) {
      final look = themeSpecs[id]!.look;
      final warrior = id == AppThemeId.warrior;
      final chantry = id == AppThemeId.chantry;
      expect(look.flat, warrior, reason: id.name);
      expect(look.statShape == StatShape.shield, warrior, reason: id.name);
      expect(look.vitalStyle == VitalStyle.plate, warrior, reason: id.name);
      expect(look.statShape == StatShape.arch, chantry, reason: id.name);
      expect(look.vitalStyle == VitalStyle.glass, chantry, reason: id.name);
      expect(look.archTiles, chantry, reason: id.name);
      expect(look.ornaments, chantry, reason: id.name);
      expect(look.frameWidth > 0, warrior || chantry, reason: id.name);
    }
  });

  test('flat boxes have square corners', () {
    expect(const ThemeLook(flat: true).radius, 0);
    expect(const ThemeLook().radius, greaterThan(0));
  });

  test('a weapon rolls attack and damage together', () {
    const numbers = WeaponNumbers(attack: 3, damage: '2d6+3', trained: true);
    final request = weaponRoll('Longsword', numbers);
    expect(request.bonus, 3);
    expect(request.damage, '2d6+3');
  });
}
