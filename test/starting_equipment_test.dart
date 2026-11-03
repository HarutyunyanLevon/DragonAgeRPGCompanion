import 'dart:io';

import 'package:dragon_age_companion/character/starting_equipment.dart';
import 'package:dragon_age_companion/features/create/gear_choices.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> readFromDisk(String path) => File(path).readAsString();

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader(readFromDisk).load();
  });

  List<String> names(Iterable items) => [for (final i in items) i.name as String];

  group('starting equipment', () {
    test('class data in classes.json', () {
      final classes = rules.classes;
      expect(classes.classById('warrior').startingArmor, 'heavy-leather');
      expect(classes.classById('warrior').startingWeapons, 3);
      expect(classes.classById('rogue').startingArmor, 'light-leather');
      expect(classes.classById('rogue').startingWeapons, 2);
      expect(classes.classById('mage').startingArmor, isNull);
      expect(classes.classById('mage').startingWeapons, 1);
      expect(classes.classById('mage').startingExtraItem, 'Staff');
    });

    test('warrior: basics, worn armor, wielded weapon', () {
      final items = startingItems(
        classRules: rules.classes.classById('warrior'),
        talentIds: const [],
        weaponIds: const ['battle-axe'],
        rules: rules,
      );
      expect(names(items),
          ['Backpack', "Traveler's garb", 'Waterskin', 'Heavy Leather', 'Battle Axe']);
      expect(items.map((i) => i.equipped), [false, false, false, true, true]);
    });

    test('Weapon and Shield Style adds a worn medium shield', () {
      final items = startingItems(
        classRules: rules.classes.classById('warrior'),
        talentIds: const ['weapon-and-shield-style'],
        weaponIds: const ['battle-axe'],
        rules: rules,
      );
      expect(items.singleWhere((i) => i.itemId == 'medium-shield').equipped,
          isTrue);
    });

    test('mage gets a staff and no armor', () {
      final items = startingItems(
        classRules: rules.classes.classById('mage'),
        talentIds: const [],
        weaponIds: const ['quarterstaff'],
        rules: rules,
      );
      expect(names(items), contains('Staff'));
      expect(items.where((i) => rules.armorById(i.itemId) != null), isEmpty);
    });

    test('bow users get a quiver and arrows, crossbow users bolts', () {
      final bow = startingItems(
        classRules: rules.classes.classById('rogue'),
        talentIds: const [],
        weaponIds: const ['long-bow', 'dagger'],
        rules: rules,
      );
      expect(names(bow), contains('Quiver'));
      expect(bow.map((i) => i.itemId), contains('arrows-20'));

      final crossbow = startingItems(
        classRules: rules.classes.classById('warrior'),
        talentIds: const [],
        weaponIds: const ['crossbow'],
        rules: rules,
      );
      expect(crossbow.map((i) => i.itemId), contains('bolts-20'));
    });

    test('weapon choices come from the weapon groups', () {
      final choices = startingWeaponChoices(const ['axes'], rules);
      expect(choices, containsAll(['battle-axe', 'throwing-axe']));
      expect(choices, isNot(contains('mace')));
    });

    test('weapon count is the class number, limited by the choices', () {
      final warrior = rules.classes.classById('warrior');
      expect(startingWeaponCount(warrior, const ['axes'], rules), 3);
      expect(
          startingWeaponCount(
              rules.classes.classById('mage'), const ['staves'], rules),
          1);
      expect(startingWeaponCount(warrior, const [], rules), 0);
    });
  });

  group('GearChoices', () {
    test('no roll means no money', () {
      expect(const GearChoices().startingCopper(rules), 0);
    });

    test('starting silver is 50 + the roll, in copper', () {
      expect(const GearChoices(silverRoll: 10).startingCopper(rules), 6000);
    });

    test('buying lowers the money, refunding gives it back', () {
      var gear = const GearChoices(silverRoll: 10);
      final price = rules.catalogEntry('arrows-20').costCp;
      gear = gear.buy('arrows-20').buy('arrows-20');
      expect(gear.count('arrows-20'), 2);
      expect(gear.leftCopper(rules), 6000 - 2 * price);
      gear = gear.refund('arrows-20');
      expect(gear.leftCopper(rules), 6000 - price);
      expect(gear.refund('mace').bought, ['arrows-20']);
    });

    test('money never drops below 0', () {
      var gear = const GearChoices(silverRoll: 3);
      for (var i = 0; i < 20; i++) {
        gear = gear.buy('heavy-leather');
      }
      expect(gear.leftCopper(rules), 0);
      expect(gear.canAfford(rules, 'heavy-leather'), isFalse);
    });
  });
}
