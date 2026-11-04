import 'dart:convert';
import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/level_up.dart';
import 'package:dragon_age_companion/rules/models/backgrounds.dart';
import 'package:dragon_age_companion/rules/models/talents.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader((path) => File(path).readAsString()).load();
  });

  Character hero({
    String classId = 'warrior',
    int level = 1,
    Map<String, int> abilities = const {
      'strength': 3,
      'dexterity': 2,
      'constitution': 2,
      'magic': 3,
    },
    List<CharacterFocus> focuses = const [],
    List<DegreeEntry> talents = const [],
    List<DegreeEntry> specializations = const [],
    List<String> owedGains = const [],
    int maxMana = 0,
  }) =>
      Character(
        id: 't',
        name: 'Test',
        backgroundId: 'fereldan-noble',
        race: 'human',
        classId: classId,
        level: level,
        abilities: abilities,
        bankedAdvancements: const {},
        focuses: focuses,
        talents: talents,
        specializations: specializations,
        spellIds: const [],
        traitIds: const [],
        weaponGroups: const ['brawling'],
        languages: const [],
        maxHealth: 40,
        health: 35,
        maxMana: maxMana,
        mana: maxMana,
        owedGains: owedGains,
        inventory: const [],
        goals: const [],
        ties: const [],
        playLayouts: const {},
      );

  const dexterityFocus = FocusRef(ability: 'dexterity', focus: 'acrobatics');
  const climbing = FocusRef(ability: 'strength', focus: 'climbing');

  group('advanceAbility', () {
    test('a rating below 6 costs one advancement', () {
      final c = advanceAbility(hero(), rules.classes, 'dexterity');
      expect(c.ability('dexterity'), 3);
      expect(c.bankedAdvancements['dexterity'], 0);
    });

    test('a rating of 6 costs two: the first one is banked', () {
      var c = hero(abilities: const {'strength': 5});
      c = advanceAbility(c, rules.classes, 'strength');
      expect(c.ability('strength'), 5);
      expect(c.bankedAdvancements['strength'], 1);

      c = advanceAbility(c, rules.classes, 'strength');
      expect(c.ability('strength'), 6);
      expect(c.bankedAdvancements['strength'], 0);
    });
  });

  group('applyLevelUp', () {
    test('warrior level 2: advancement, health, both focuses', () {
      final c = applyLevelUp(
        hero(),
        rules,
        const LevelUpChoices(
          ability: 'dexterity',
          healthDie: 4,
          focus: dexterityFocus,
          classFocus: climbing,
        ),
      );

      expect(c.level, 2);
      expect(c.ability('dexterity'), 3);
      expect(c.maxHealth, 46); // 40 + d6 4 + Constitution 2
      expect(c.health, 41);
      expect([for (final f in c.focuses) f.focus], ['acrobatics', 'climbing']);
      expect(c.owedGains, isEmpty);
      expect(c.levelUpUndo, isNotNull);
    });

    test('health and mana use the ability after the advancement', () {
      final c = applyLevelUp(
        hero(
          classId: 'mage',
          abilities: const {'magic': 3, 'constitution': 1},
          maxMana: 14,
        ),
        rules,
        const LevelUpChoices(
          ability: 'magic', // primary at level 2
          healthDie: 3,
          manaDie: 5,
          focus: FocusRef(ability: 'magic', focus: 'spirit'),
          spellId: 'flame-blast',
        ),
      );

      expect(c.ability('magic'), 4);
      expect(c.maxHealth, 44); // 40 + 3 + Constitution 1
      expect(c.maxMana, 23); // 14 + 5 + Magic 4
      expect(c.mana, 23);
      expect(c.spellIds, ['flame-blast']);
    });

    test('skipped gains become owed gains', () {
      final c = applyLevelUp(
        hero(),
        rules,
        const LevelUpChoices(ability: 'strength', healthDie: 1),
      );

      // Level 2 is even: a primary focus, plus the warrior's class focus.
      expect(c.owedGains, [owedFocusPrimary, owedClassFocus(2)]);
      expect(c.focuses, isEmpty);
    });

    test('a talent the character has gains its next degree', () {
      final c = applyLevelUp(
        hero(
          level: 2,
          talents: const [DegreeEntry(id: 'single-weapon-style', degree: 1)],
        ),
        rules,
        const LevelUpChoices(
          ability: 'communication', // secondary at level 3
          healthDie: 2,
          focus: FocusRef(ability: 'communication', focus: 'etiquette'),
          talentId: 'single-weapon-style',
        ),
      );

      expect(c.talents.single.degree, 2);
    });

    test('a later step of a specialization slot raises its degree', () {
      final c = applyLevelUp(
        hero(
          level: 7,
          specializations: const [
            DegreeEntry(id: 'champion', degree: 1, slot: 6),
          ],
        ),
        rules,
        const LevelUpChoices(ability: 'strength', healthDie: 2),
      );

      expect(c.level, 8);
      expect(c.specializations.single.degree, 2); // Journeyman at level 8
    });

    test('level 6 without a pick owes the slot 6 specialization', () {
      final c = applyLevelUp(
        hero(level: 5),
        rules,
        const LevelUpChoices(ability: 'strength', healthDie: 2),
      );

      expect(c.owedGains, contains(owedSpecialization(6)));
    });
  });

  group('undoLevelUp', () {
    test('restores the level-up fields and keeps the rest', () {
      final leveled = applyLevelUp(
        hero(),
        rules,
        const LevelUpChoices(
          ability: 'dexterity',
          healthDie: 4,
          focus: dexterityFocus,
          classFocus: climbing,
        ),
      ).copyWith(copper: 500, health: 10);

      final undone = undoLevelUp(leveled);

      expect(undone.level, 1);
      expect(undone.ability('dexterity'), 2);
      expect(undone.focuses, isEmpty);
      expect(undone.maxHealth, 40);
      expect(undone.health, 10); // current health is not restored
      expect(undone.copper, 500);
      expect(undone.levelUpUndo, isNull);
    });

    test('current health above the old maximum is lowered to it', () {
      final undone = undoLevelUp(applyLevelUp(
        hero(),
        rules,
        const LevelUpChoices(ability: 'strength', healthDie: 6),
      ).copyWith(health: 48));

      expect(undone.health, 40);
    });

    test('forgets only the spell the level-up taught', () {
      final leveled = applyLevelUp(
        hero(classId: 'mage', maxMana: 10),
        rules,
        const LevelUpChoices(
            ability: 'magic', healthDie: 1, manaDie: 1, spellId: 'flame-blast'),
      );
      final later = leveled.copyWith(spellIds: [...leveled.spellIds, 'stonefist']);

      expect(undoLevelUp(later).spellIds, ['stonefist']);
    });
  });

  group('owed gains and options', () {
    test('withoutOwed removes one entry only', () {
      final c = withoutOwed(
          hero(owedGains: const [owedTalent, owedTalent]), owedTalent);
      expect(c.owedGains, [owedTalent]);
    });

    test('a specialization added late starts at the degree of its slot', () {
      expect(specializationDegreeAt(6, 6), 1);
      expect(specializationDegreeAt(6, 7), 1);
      expect(specializationDegreeAt(6, 9), 2);
      expect(specializationDegreeAt(6, 10), 3);

      final c = addSpecialization(hero(level: 9), 'champion', 6);
      expect(c.specializations.single.degree, 2);
      expect(c.specializations.single.slot, 6);
    });

    test('requirements: ability minimum and story', () {
      const needs3 = Requirement(type: 'ability', ability: 'strength', min: 3);
      const needs4 = Requirement(type: 'ability', ability: 'strength', min: 4);
      const story = Requirement(type: 'story', text: 'GM approval');

      expect(meetsPrerequisite(hero(), needs3), isTrue);
      expect(meetsPrerequisite(hero(), needs4), isFalse);
      expect(meetsPrerequisite(hero(), story), isFalse);
    });

    test('focus options leave out the focuses the character has', () {
      final options = focusChoices(
        hero(focuses: const [
          CharacterFocus(ability: 'dexterity', focus: 'acrobatics'),
        ]),
        rules,
        ['dexterity'],
      );

      expect(options, isNotEmpty);
      expect(options.map((f) => f.focus), isNot(contains('acrobatics')));
      expect(options.every((f) => f.ability == 'dexterity'), isTrue);
    });

    test('talent options are the class talents below Master', () {
      final options = talentChoices(
        hero(talents: const [DegreeEntry(id: 'armor-training', degree: 3)]),
        rules,
      );

      expect(options.every((t) => t.classes.contains('warrior')), isTrue);
      expect(options.map((t) => t.id), isNot(contains('armor-training')));
    });
  });

  group('rules data', () {
    test('every class has a row for levels 1 to $maxLevel', () {
      for (final classRules in rules.classes.classes) {
        for (var level = 1; level <= maxLevel; level++) {
          expect(() => LevelPlan(classRules, level), returnsNormally);
        }
      }
    });

    test('class focus choices are real focuses', () {
      for (final classRules in rules.classes.classes) {
        for (final level in classRules.levels) {
          for (final choice in level.focusChoices) {
            expect(
              rules.focuses.any(
                  (f) => f.id == choice.focus && f.ability == choice.ability),
              isTrue,
              reason: '${choice.ability} ${choice.focus}',
            );
          }
        }
      }
    });

    test('every specialization step is on a slot level', () {
      for (final classRules in rules.classes.classes) {
        for (final level in classRules.levels) {
          final step = level.specialization;
          if (step != null) expect([6, 14], contains(step.slot));
        }
      }
    });
  });

  test('owed gains, the undo data and the slot survive a save and load', () {
    final leveled = applyLevelUp(
      hero(),
      rules,
      const LevelUpChoices(ability: 'strength', healthDie: 3),
    ).copyWith(
      specializations: const [DegreeEntry(id: 'champion', degree: 1, slot: 6)],
    );

    final copy = Character.fromJson(
        jsonDecode(jsonEncode(leveled.toJson())) as Map<String, dynamic>);

    expect(copy.owedGains, leveled.owedGains);
    expect(copy.levelUpUndo!.level, 1);
    expect(copy.levelUpUndo!.maxHealth, 40);
    expect(copy.specializations.single.slot, 6);
  });
}
