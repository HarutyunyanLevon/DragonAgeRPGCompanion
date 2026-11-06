import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dragon_age_companion/character/damage_roll.dart';
import 'package:dragon_age_companion/character/magic.dart';
import 'package:dragon_age_companion/rules/models/spell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const heal = SpellEffect(label: 'Healing', dice: '1d6', perMana: 1);
  const groupHeal = SpellEffect(label: 'Healing', dice: '1d6', perMana: 3);
  const lightning = SpellEffect(label: 'Damage', dice: '2d6', plus: 'magic');

  group('effectFormula', () {
    test('a fixed effect is rolled once', () {
      expect(effectFormula(lightning, mana: 6), '2d6');
    });

    test('the ability is added', () {
      expect(effectFormula(lightning, mana: 6, bonus: 4), '2d6+4');
      expect(effectFormula(lightning, mana: 6, bonus: -1), '2d6-1');
    });

    test('a flat part of the dice text is kept', () {
      const flame = SpellEffect(label: 'Damage', dice: '2d6+1');
      expect(effectFormula(flame, mana: 3), '2d6+1');
      expect(effectFormula(flame, mana: 3, bonus: 2), '2d6+3');
    });

    test('one die per mana point (Heal)', () {
      expect(effectFormula(heal, mana: 1), '1d6');
      expect(effectFormula(heal, mana: 3), '3d6');
    });

    test('one die per 3 mana (Group Heal)', () {
      expect(effectFormula(groupHeal, mana: 3), '1d6');
      expect(effectFormula(groupHeal, mana: 9), '3d6');
      expect(effectFormula(groupHeal, mana: 2), isNull);
    });

    test('text that is not dice gives nothing', () {
      const odd = SpellEffect(label: 'x', dice: 'a lot');
      expect(effectFormula(odd, mana: 3), isNull);
    });
  });

  test('every effect in spells.json can be rolled', () {
    final list = jsonDecode(File('assets/rules/spells.json').readAsStringSync())
        as List<dynamic>;
    final spells = [for (final s in list) Spell.fromJson(s as Map<String, dynamic>)];

    final withEffects = spells.where((s) => s.effects.isNotEmpty);
    expect(withEffects.length, greaterThan(20));
    for (final spell in withEffects) {
      for (final effect in spell.effects) {
        final formula = effectFormula(effect, mana: 9, bonus: 3);
        expect(formula, isNotNull, reason: '${spell.name}: ${effect.label}');
        expect(DamageRoll.tryRoll(formula!, Random()), isNotNull,
            reason: '${spell.name}: $formula');
      }
    }
  });

  test('an effect survives saving and loading (homebrew spells)', () {
    final effect = SpellEffect.fromJson(heal.toJson());
    expect(effect.label, 'Healing');
    expect(effect.perMana, 1);
    expect(effect.plus, isNull);
  });
}
