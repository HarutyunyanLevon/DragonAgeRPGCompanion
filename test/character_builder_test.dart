import 'dart:io';

import 'package:dragon_age_companion/features/create/ability_generation.dart';
import 'package:dragon_age_companion/features/create/background_benefits.dart';
import 'package:dragon_age_companion/features/create/character_builder.dart';
import 'package:dragon_age_companion/features/create/character_draft.dart';
import 'package:dragon_age_companion/features/create/class_choices.dart';
import 'package:dragon_age_companion/features/create/gear_choices.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader((path) => File(path).readAsString()).load();
  });

  AbilityGeneration scores(Map<String, int> given) => AbilityGeneration(
        method: AbilityMethod.manual,
        scores: {for (final a in rules.backgrounds.abilities) a: given[a] ?? 0},
      );

  group('buildCharacter', () {
    test('warrior: abilities, focuses, weapon groups, talents, health', () {
      // Fereldan Noble (+1 Strength; focus choice 0 = Military Lore).
      // Table rows used: 0 = +1 Constitution, 1 = Cunning (Heraldry).
      final draft = CharacterDraft(
        name: ' Aveline ',
        background: rules.backgrounds.backgroundById('fereldan-noble'),
        race: 'human',
        classId: 'warrior',
        abilities: scores({'strength': 2, 'dexterity': 1, 'constitution': 1}),
        benefits: const BackgroundBenefits(focusIndex: 0, rolled: [0, 1]),
        classChoices: const ClassChoices(
          weaponGroups: ['axes', 'bludgeons', 'polearms'],
          talents: ['single-weapon-style', 'two-hander-style'],
        ),
      );

      final c = buildCharacter(
          draft: draft, rules: rules, id: '1', healthDie: 4);

      expect(c.name, 'Aveline');
      expect(c.abilities['strength'], 3); // 2 + background
      expect(c.abilities['constitution'], 2); // 1 + table
      expect(c.abilities['dexterity'], 1);
      expect([for (final f in c.focuses) f.focus], ['military-lore', 'heraldry']);
      expect(c.weaponGroups, ['brawling', 'axes', 'bludgeons', 'polearms']);
      expect([for (final t in c.talents) t.id],
          ['armor-training', 'single-weapon-style', 'two-hander-style']);
      expect(c.languages, ['trade-tongue']);
      expect(c.maxHealth, 36); // 30 + Constitution 2 + d6 4
      expect(c.health, c.maxHealth);
      expect(c.maxMana, 0);
    });

    test('the background\'s racial trait is stored on the character', () {
      CharacterDraft draftFor(String background, String race) => CharacterDraft(
            name: 'Test',
            background: rules.backgrounds.backgroundById(background),
            race: race,
            classId: 'warrior',
            abilities: scores({}),
            benefits: const BackgroundBenefits(focusIndex: 0, rolled: [0, 1]),
            classChoices: const ClassChoices(
              weaponGroups: ['axes', 'bludgeons', 'polearms'],
              talents: ['single-weapon-style', 'two-hander-style'],
            ),
          );

      final dwarf = buildCharacter(
          draft: draftFor('surface-dwarf', 'dwarf'),
          rules: rules,
          id: '1',
          healthDie: 1);
      final human = buildCharacter(
          draft: draftFor('fereldan-noble', 'human'),
          rules: rules,
          id: '2',
          healthDie: 1);

      expect(dwarf.traitIds, ['magic-resistance']);
      expect(human.traitIds, isEmpty);
    });

    test('starting gear, purchases and leftover money', () {
      final draft = CharacterDraft(
        name: 'Aveline',
        background: rules.backgrounds.backgroundById('fereldan-noble'),
        race: 'human',
        classId: 'warrior',
        abilities: scores({'strength': 2, 'dexterity': 1, 'constitution': 1}),
        benefits: const BackgroundBenefits(focusIndex: 0, rolled: [0, 1]),
        classChoices: const ClassChoices(
          weaponGroups: ['axes', 'bludgeons', 'polearms'],
          talents: ['single-weapon-style', 'two-hander-style'],
        ),
        gearChoices: const GearChoices(
          weaponIds: ['battle-axe'],
          silverRoll: 10,
          bought: ['arrows-20', 'arrows-20'],
        ),
      );

      final c = buildCharacter(
          draft: draft, rules: rules, id: '1', healthDie: 4);

      final heavy = c.inventory.singleWhere((i) => i.itemId == 'heavy-leather');
      expect(heavy.equipped, isTrue);
      final axe = c.inventory.singleWhere((i) => i.itemId == 'battle-axe');
      expect(axe.equipped, isTrue);
      final arrows = c.inventory.singleWhere((i) => i.itemId == 'arrows-20');
      expect(arrows.quantity, 2); // bought twice, stacked
      expect(arrows.equipped, isFalse);
      expect(c.copper,
          6000 - 2 * rules.catalogEntry('arrows-20').costCp);
    });

    test('mage: mana, spells and the table results', () {
      // Circle Mage (human; +1 Magic; focus choice 0 = Arcane Lore).
      // Human table rows: 0 = +1 Willpower, 4 = +1 Cunning.
      final balanced =
          rules.starterSets.firstWhere((s) => s.name == 'Balanced');
      final draft = CharacterDraft(
        name: 'Anders',
        background: rules.backgrounds.backgroundById('circle-mage'),
        race: 'human',
        classId: 'mage',
        abilities: scores({'magic': 3, 'willpower': 2, 'cunning': 1}),
        benefits: const BackgroundBenefits(focusIndex: 0, rolled: [0, 4]),
        classChoices:
            ClassChoices(talents: const ['lore'], spells: balanced.spells),
      );

      final c = buildCharacter(
          draft: draft, rules: rules, id: '2', healthDie: 3, manaDie: 2);

      expect(c.abilities['magic'], 4);
      expect(c.abilities['willpower'], 3);
      expect(c.abilities['cunning'], 2);
      expect(c.maxHealth, 23); // 20 + Constitution 0 + 3
      expect(c.maxMana, 16); // 10 + Magic 4 + 2
      expect(c.mana, 16);
      expect(c.spellIds, balanced.spells);
      expect(c.weaponGroups, ['brawling', 'staves']);
    });

    test('the same focus twice is kept once', () {
      // Apostate (human): focus choice 1 = Self-Discipline, table row 2 = the same.
      final draft = CharacterDraft(
        name: 'Twice',
        background: rules.backgrounds.backgroundById('apostate'),
        race: 'human',
        classId: 'mage',
        abilities: scores({}),
        benefits: const BackgroundBenefits(focusIndex: 1, rolled: [2, 0]),
        classChoices: const ClassChoices(talents: ['lore']),
      );

      final c = buildCharacter(draft: draft, rules: rules, id: '3', healthDie: 1);

      expect([for (final f in c.focuses) f.focus], ['self-discipline']);
    });
  });

  group('class choices', () {
    test('warrior groups leave out what the background gave', () {
      // Orlesian Exile table row 6 = Weapon group: Light Blades.
      final draft = CharacterDraft(
        name: 'x',
        background: rules.backgrounds.backgroundById('orlesian-exile'),
        race: 'human',
        classId: 'warrior',
        abilities: scores({}),
        benefits: const BackgroundBenefits(focusIndex: 0, rolled: [6, 0]),
      );
      final warrior = rules.classes.classById('warrior');

      final groups = availableWeaponGroups(
          warrior, draft.benefits.results(draft.benefitFacts(rules)));

      expect(groups, isNot(contains('light-blades')));
      expect(groups, contains('axes'));
    });

    test('isComplete wants exactly what the class asks for', () {
      final warrior = rules.classes.classById('warrior');
      const done = ClassChoices(
        weaponGroups: ['axes', 'bows', 'spears'],
        talents: ['archery-style', 'single-weapon-style'],
      );

      expect(done.isComplete(warrior), isTrue);
      expect(done.withTalents(['archery-style']).isComplete(warrior), isFalse);
      expect(const ClassChoices().isComplete(warrior), isFalse);
    });

    test('toggling adds, then removes', () {
      final once = const ClassChoices().toggleSpell('heal');
      expect(once.spells, ['heal']);
      expect(once.toggleSpell('heal').spells, isEmpty);
    });
  });

  group('rules data', () {
    test('starter sets: 3 real spells each, none with a requirement', () {
      expect(rules.starterSets, hasLength(5));
      for (final set in rules.starterSets) {
        expect(set.spells, hasLength(3), reason: set.name);
        for (final id in set.spells) {
          expect(rules.spellById(id).hasNoRequirement, isTrue, reason: id);
        }
      }
    });

    test('classes: only the mage has mana and starting spells', () {
      final mage = rules.classes.classById('mage');
      expect(mage.mana!.startBase, 10);
      expect(mage.mana!.plus, 'magic');
      expect(mage.startingSpells, 3);
      expect(rules.classes.classById('rogue').mana, isNull);
      expect(rules.classes.classById('warrior').startingSpells, 0);
    });

    test('every pickable starting talent exists', () {
      for (final c in rules.classes.classes) {
        for (final id in [
          ...c.startingTalents.fixed,
          ...c.startingTalents.pickFrom,
        ]) {
          expect(rules.talents.talentById(id).name, isNotEmpty);
        }
      }
    });
  });
}
