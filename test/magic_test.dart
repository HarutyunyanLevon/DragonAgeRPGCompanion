import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/magic.dart';
import 'package:dragon_age_companion/character/test_roll.dart';
import 'package:dragon_age_companion/rules/models/spell.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> readFromDisk(String path) => File(path).readAsString();

Character mage({
  List<CharacterFocus> focuses = const [],
  List<DegreeEntry> talents = const [],
  List<DegreeEntry> specializations = const [],
  List<String> spellIds = const [],
  List<InventoryItem> inventory = const [],
  String classId = 'mage',
}) =>
    Character(
      id: 'm1',
      name: 'Morrigan',
      backgroundId: 'fereldan-freeman',
      race: 'human',
      classId: classId,
      abilities: const {'magic': 3, 'willpower': 2},
      bankedAdvancements: const {},
      focuses: focuses,
      talents: talents,
      specializations: specializations,
      spellIds: spellIds,
      traitIds: const [],
      weaponGroups: const [],
      languages: const [],
      maxHealth: 30,
      health: 30,
      maxMana: 20,
      mana: 20,
      inventory: inventory,
      owedGains: const [],
      goals: const [],
      ties: const [],
      playLayouts: const {},
    );

Spell spell({
  String school = 'Primal',
  String tn = '12',
  List<SpellRequirement> requires = const [],
}) =>
    Spell(
      name: 'Test Spell',
      school: school,
      type: 'Attack',
      mana: '3 MP',
      castTime: 'Major Action',
      tn: tn,
      test: 'Constitution (Stamina) vs. Spellpower',
      requirement: requires.isEmpty ? 'None' : 'Something',
      description: '',
      requires: requires,
    );

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader(readFromDisk).load();
  });

  group('parseManaCost', () {
    test('fixed, range and open-ended costs', () {
      final fixed = parseManaCost('7 MP')!;
      expect((fixed.min, fixed.max, fixed.isFixed), (7, 7, true));

      final range = parseManaCost('1-3 MP')!;
      expect((range.min, range.max, range.isFixed), (1, 3, false));

      final open = parseManaCost('20+ MP')!;
      expect((open.min, open.max), (20, null));
    });

    test('anything else is null', () {
      expect(parseManaCost(''), isNull);
      expect(parseManaCost('lots'), isNull);
      expect(parseManaCost('5'), isNull);
    });
  });

  group('TestRoll', () {
    test('doubles are any two equal dice', () {
      expect(const TestRoll([2, 2, 5]).hasDoubles, isTrue);
      expect(const TestRoll([2, 5, 2]).hasDoubles, isTrue);
      expect(const TestRoll([5, 2, 2]).hasDoubles, isTrue);
      expect(const TestRoll([1, 2, 3]).hasDoubles, isFalse);
    });

    test('the last die is the Dragon Die; total adds the bonus', () {
      const roll = TestRoll([1, 2, 6]);
      expect(roll.dragonDie, 6);
      expect(roll.sum, 9);
      expect(roll.total(4), 13);
    });
  });

  group('casting numbers', () {
    test('only mages can cast', () {
      expect(canCast(mage(), rules), isTrue);
      expect(canCast(mage(classId: 'warrior'), rules), isFalse);
    });

    test('casting bonus is Magic plus the school focus', () {
      final withFocus = mage(
          focuses: const [CharacterFocus(ability: 'magic', focus: 'primal')]);
      expect(castingBonus(mage(), spell()), 3);
      expect(castingBonus(withFocus, spell()), 5);
      expect(spellpower(withFocus, spell()), 15);
      // A focus of another school does not count.
      expect(castingBonus(withFocus, spell(school: 'Entropy')), 3);
    });

    test('target number falls back to 10', () {
      expect(spellTn(spell(tn: '14')), 14);
      expect(spellTn(spell(tn: 'varies')), 10);
    });

    test('armor strain comes from the equipped armor only', () {
      final worn = mage(inventory: const [
        InventoryItem(name: 'Mail', itemId: 'heavy-mail', equipped: true),
      ]);
      final carried = mage(inventory: const [
        InventoryItem(name: 'Mail', itemId: 'heavy-mail'),
      ]);
      expect(armorStrain(worn, rules), 4);
      expect(armorStrain(carried, rules), 0);
      expect(armorStrain(mage(), rules), 0);
    });
  });

  group('requirements', () {
    const needsSpell = SpellRequirement(type: 'spell', id: 'arcane-bolt');
    const needsTalent =
        SpellRequirement(type: 'talent', id: 'entropy-magic', degree: 2);
    const needsSpec =
        SpellRequirement(type: 'specialization', id: 'blood-mage');

    test('a spell without requirements is always learnable', () {
      expect(unmetRequirements(mage(), spell()), isEmpty);
    });

    test('spells, talent degrees and specializations are checked', () {
      final target = spell(requires: [needsSpell, needsTalent, needsSpec]);
      expect(unmetRequirements(mage(), target), hasLength(3));

      final ready = mage(
        spellIds: const ['arcane-bolt'],
        talents: const [DegreeEntry(id: 'entropy-magic', degree: 2)],
        specializations: const [DegreeEntry(id: 'blood-mage', degree: 1)],
      );
      expect(unmetRequirements(ready, target), isEmpty);
    });

    test('a talent degree that is too low does not count', () {
      final novice = mage(
          talents: const [DegreeEntry(id: 'entropy-magic', degree: 1)]);
      expect(meetsRequirement(novice, needsTalent), isFalse);
    });
  });

  group('mishaps', () {
    final needy = spell(
        requires: const [SpellRequirement(type: 'spell', id: 'arcane-bolt')]);

    test('need a failed roll, Dragon Die 1 and a requirement', () {
      const onesFail = TestRoll([3, 4, 1]);
      expect(causesMishap(needy, onesFail, success: false), isTrue);
      expect(causesMishap(needy, onesFail, success: true), isFalse);
      expect(
          causesMishap(needy, const TestRoll([3, 4, 2]), success: false),
          isFalse);
      expect(causesMishap(spell(), onesFail, success: false), isFalse);
    });
  });

  group('rules data', () {
    test('magic.json loads', () {
      expect(rules.magic.armorStrain['light-leather'], 1);
      expect(rules.magic.standardStunts, isNotEmpty);
      expect(rules.magic.mishapFor(1).name, isNotEmpty);
    });

    test('every spell requirement points at something that exists', () {
      final spellIds = rules.spells.map((s) => s.id).toSet();
      for (final s in rules.spells) {
        for (final r in s.requires) {
          switch (r.type) {
            case 'spell':
              expect(spellIds, contains(r.id), reason: s.name);
            case 'talent':
              expect(rules.talents.talents.any((t) => t.id == r.id), isTrue,
                  reason: '${s.name}: ${r.id}');
            case 'specialization':
              expect(
                  rules.specializations.specializations
                      .any((x) => x.id == r.id),
                  isTrue,
                  reason: '${s.name}: ${r.id}');
            default:
              fail('${s.name}: unknown requirement type ${r.type}');
          }
        }
      }
    });

    test('requires is empty exactly when the requirement text is', () {
      for (final s in rules.spells) {
        final text = s.requirement.trim().toLowerCase();
        expect(s.requires.isEmpty, text.isEmpty || text == 'none',
            reason: s.name);
      }
    });
  });
}
