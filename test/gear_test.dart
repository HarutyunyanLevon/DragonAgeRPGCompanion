import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:dragon_age_companion/shared/money.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> readFromDisk(String path) => File(path).readAsString();

void main() {
  final loader = RulesLoader(readFromDisk);

  group('gear.json', () {
    test('armor, shields and weapons are read', () async {
      final gear = await loader.loadGear();
      expect(gear.armor.map((a) => a.id), containsAll(['light-leather', 'heavy-leather']));
      expect(gear.shields.map((s) => s.defenseBonus), containsAll([1, 2, 3]));
      expect(gear.weapons, isNotEmpty);
    });

    test('catalog ids are unique, so an item id finds one entry', () async {
      final gear = await loader.loadGear();
      final ids = gear.catalog.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('catalog has every kind of item', () async {
      final gear = await loader.loadGear();
      final categories = gear.catalog.map((e) => e.category).toSet();
      expect(categories, containsAll(['armor', 'shields', 'weapons', 'ammunition', 'traveling']));
    });

    test('missile weapons have a range, melee weapons do not', () async {
      final gear = await loader.loadGear();
      final longBow = gear.weapons.firstWhere((w) => w.id == 'long-bow');
      expect(longBow.range, isNotNull);
      expect(longBow.range!.short, lessThan(longBow.range!.long));
      expect(gear.weapons.firstWhere((w) => w.id == 'battle-axe').range, isNull);
    });

    test('every weapon group has a weapon focus', () async {
      final gear = await loader.loadGear();
      final focuses = await loader.loadFocuses();
      for (final group in gear.weaponGroups) {
        expect(focuses.where((f) => f.weaponGroup == group.id), hasLength(1),
            reason: group.id);
      }
    });
  });

  group('specializations.json', () {
    test('all 21 are read, with their class', () async {
      final file = await loader.loadSpecializations();
      expect(file.specializations, hasLength(21));
      expect(file.specializations.every((s) => s.classId.isNotEmpty), isTrue);
    });
  });

  group('inventory in a saved character', () {
    test('equipped survives JSON, and older saves default to false', () {
      const item = InventoryItem(name: 'Mace', itemId: 'mace', equipped: true);
      final copy = InventoryItem.fromJson(item.toJson());
      expect(copy.equipped, isTrue);

      final old = InventoryItem.fromJson({'name': 'Rope'});
      expect(old.equipped, isFalse);
      expect(old.quantity, 1);
    });
  });

  group('money', () {
    test('copper splits into gold, silver and copper', () {
      final parts = splitCopper(12345);
      expect((parts.gold, parts.silver, parts.copper), (1, 23, 45));
    });

    test('toCopper is the reverse', () {
      expect(toCopper(gold: 1, silver: 23, copper: 45), 12345);
      expect(toCopper(silver: 5), 500);
    });
  });
}
