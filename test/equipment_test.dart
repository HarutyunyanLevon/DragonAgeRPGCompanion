import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/equipment.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> readFromDisk(String path) => File(path).readAsString();

Character makeCharacter({
  String classId = 'warrior',
  String race = 'human',
  Map<String, int> abilities = const {'strength': 3, 'dexterity': 2},
  List<CharacterFocus> focuses = const [],
  List<DegreeEntry> talents = const [],
  List<String> weaponGroups = const ['axes'],
  List<InventoryItem> inventory = const [],
}) =>
    Character(
      id: 'c1',
      name: 'Test',
      backgroundId: 'fereldan-freeman',
      race: race,
      classId: classId,
      abilities: abilities,
      bankedAdvancements: const {},
      focuses: focuses,
      talents: talents,
      specializations: const [],
      spellIds: const [],
      weaponGroups: weaponGroups,
      languages: const [],
      maxHealth: 30,
      health: 30,
      inventory: inventory,
      goals: const [],
      ties: const [],
    );

InventoryItem item(String id, {bool equipped = false}) =>
    InventoryItem(name: id, itemId: id, equipped: equipped);

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader(readFromDisk).load();
  });

  group('equipping', () {
    test('a second armor replaces the first', () {
      final inventory = [
        item('heavy-leather', equipped: true),
        item('light-leather'),
        item('battle-axe', equipped: true),
      ];
      final result = toggleEquipped(inventory, 1, rules);
      expect(result.map((i) => i.equipped), [false, true, true]);
    });

    test('any number of weapons can be equipped', () {
      final inventory = [item('battle-axe', equipped: true), item('mace')];
      final result = toggleEquipped(inventory, 1, rules);
      expect(result.map((i) => i.equipped), [true, true]);
    });

    test('toggling an equipped item unequips it', () {
      final result = toggleEquipped([item('mace', equipped: true)], 0, rules);
      expect(result.single.equipped, isFalse);
    });

    test('only armor, shields and weapons can be equipped', () {
      expect(canEquip(rules, item('heavy-leather')), isTrue);
      expect(canEquip(rules, item('medium-shield')), isTrue);
      expect(canEquip(rules, item('mace')), isTrue);
      expect(canEquip(rules, item('arrows-20')), isFalse);
      expect(canEquip(rules, const InventoryItem(name: 'Lucky coin')), isFalse);
    });

    test('adding a known item again raises its quantity', () {
      final result = addItem([item('arrows-20')], item('arrows-20'));
      expect(result, hasLength(1));
      expect(result.single.quantity, 2);
    });

    test('custom items are always new rows', () {
      const coin = InventoryItem(name: 'Lucky coin');
      expect(addItem([coin], coin), hasLength(2));
    });
  });

  group('combat numbers', () {
    test('no armor: plain Defense and Speed', () {
      final numbers = combatNumbers(makeCharacter(), rules);
      expect(numbers.defense, 12); // 10 + Dexterity 2
      expect(numbers.speed, 12); // human 10 + Dexterity 2
      expect(numbers.armorRating, 0);
    });

    test('armor penalty lowers Speed, and Defense without Armor Training', () {
      final character =
          makeCharacter(inventory: [item('heavy-leather', equipped: true)]);
      final numbers = combatNumbers(character, rules);
      expect(numbers.armorRating, 4);
      expect(numbers.speed, 11); // 10 + 2 - 1
      expect(numbers.defense, 11); // 10 + (2 - 1)
    });

    test('Armor Training keeps Defense intact', () {
      final character = makeCharacter(
        talents: const [DegreeEntry(id: 'armor-training', degree: 1)],
        inventory: [item('heavy-leather', equipped: true)],
      );
      final numbers = combatNumbers(character, rules);
      expect(numbers.defense, 12);
      expect(numbers.speed, 11);
    });

    test('a shield gives +1 only, until Weapon and Shield Style', () {
      final inventory = [item('medium-shield', equipped: true)];
      expect(combatNumbers(makeCharacter(inventory: inventory), rules).defense,
          13);
      final trained = makeCharacter(
        talents: const [DegreeEntry(id: 'weapon-and-shield-style', degree: 1)],
        inventory: inventory,
      );
      expect(combatNumbers(trained, rules).defense, 14);
    });

    test('Speed starts from the race', () {
      expect(combatNumbers(makeCharacter(race: 'elf'), rules).speed, 14);
      expect(combatNumbers(makeCharacter(race: 'dwarf'), rules).speed, 10);
    });

    test('unequipped armor does nothing', () {
      final character = makeCharacter(inventory: [item('heavy-leather')]);
      expect(combatNumbers(character, rules).armorRating, 0);
    });
  });

  group('weapon numbers', () {
    const axeFocus = CharacterFocus(ability: 'strength', focus: 'axes');

    test('trained with the weapon focus', () {
      final character = makeCharacter(focuses: const [axeFocus]);
      final numbers =
          weaponNumbers(character, rules.weaponById('battle-axe')!, rules);
      expect(numbers.attack, 5); // Strength 3 + focus 2
      expect(numbers.damage, '2d6+3');
      expect(numbers.trained, isTrue);
    });

    test('a doubled focus gives +3', () {
      final character = makeCharacter(focuses: const [
        CharacterFocus(ability: 'strength', focus: 'axes', doubled: true)
      ]);
      final numbers =
          weaponNumbers(character, rules.weaponById('battle-axe')!, rules);
      expect(numbers.attack, 6);
    });

    test('untrained: -2 attack', () {
      final character = makeCharacter(weaponGroups: const []);
      final numbers =
          weaponNumbers(character, rules.weaponById('battle-axe')!, rules);
      expect(numbers.attack, 1);
      expect(numbers.trained, isFalse);
    });

    test('too weak for the weapon: 1d6-1 plus the ability', () {
      final character = makeCharacter(abilities: const {'strength': 2});
      final numbers =
          weaponNumbers(character, rules.weaponById('two-handed-axe')!, rules);
      expect(numbers.damage, '1d6+1');
    });

    test('bows attack with Dexterity and add Perception to damage', () {
      final character = makeCharacter(
        abilities: const {'strength': 1, 'dexterity': 2, 'perception': 1},
        weaponGroups: const ['bows'],
      );
      final numbers =
          weaponNumbers(character, rules.weaponById('long-bow')!, rules);
      expect(numbers.attack, 2);
      expect(numbers.damage, '1d6+4');
    });

    test('addToDice', () {
      expect(addToDice('2d6', 3), '2d6+3');
      expect(addToDice('2d6', 0), '2d6');
      expect(addToDice('2d6', -1), '2d6-1');
      expect(addToDice('1d6+2', 1), '1d6+3');
      expect(addToDice('1d6-1', 1), '1d6');
      expect(addToDice('fist', 2), 'fist');
    });
  });
}
