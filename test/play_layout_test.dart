import 'dart:io';
import 'dart:math';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/damage_roll.dart';
import 'package:dragon_age_companion/character/play_items.dart';
import 'package:dragon_age_companion/character/play_layout.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:dragon_age_companion/shared/device_class.dart';
import 'package:flutter_test/flutter_test.dart';

PlayTile tile(String widget) => PlayTile(widget: widget, width: 2, height: 1);

void main() {
  group('layout changes', () {
    PlayTile at(String id, int x, int y, [int w = 2, int h = 2]) =>
        PlayTile(widget: id, x: x, y: y, width: w, height: h);
    PlayTile named(List<PlayTile> tiles, String id) =>
        tiles.firstWhere((t) => t.widget == id);

    test('moving onto another tile pushes it down', () {
      final tiles = [at('a', 0, 0), at('b', 2, 0)];
      final moved = moveTile(tiles, 'b', 0, 0, 4);
      expect(named(moved, 'b').y, 0);
      expect(named(moved, 'a').y, 2);
    });

    test('a tile stays inside the columns', () {
      final moved = moveTile([at('a', 0, 0)], 'a', 9, -3, 4);
      expect(named(moved, 'a').x, 2);
      expect(named(moved, 'a').y, 0);
    });

    test('resizing pushes tiles in the way down', () {
      final tiles = [at('a', 0, 0), at('b', 0, 2)];
      final resized = resizeTile(tiles, 'a', 4, 3, 4);
      expect(named(resized, 'a').height, 3);
      expect(named(resized, 'b').y, 3);
    });

    test('tiles never overlap after settle', () {
      final tiles = settle([at('a', 0, 0), at('b', 1, 1), at('c', 0, 1)], 'a');
      for (var i = 0; i < tiles.length; i++) {
        for (var j = i + 1; j < tiles.length; j++) {
          expect(tilesOverlap(tiles[i], tiles[j]), isFalse);
        }
      }
    });

    test('clampInt', () {
      expect(clampInt(0, 1, 4), 1);
      expect(clampInt(9, 1, 4), 4);
      expect(clampInt(3, 1, 4), 3);
    });

    test('device classes follow the window width', () {
      expect(deviceClassFor(400), DeviceClass.phone);
      expect(deviceClassFor(700), DeviceClass.tablet);
      expect(deviceClassFor(1400), DeviceClass.desktop);
    });
  });

  group('rules data for the Play tab', () {
    test('default layouts name only known widgets, each once', () async {
      final rules =
          await RulesLoader((path) => File(path).readAsString()).load();
      final ids = rules.widgetTemplates.map((w) => w.id).toSet();
      expect(ids.length, rules.widgetTemplates.length);
      for (final device in DeviceClass.values) {
        final tiles = rules.defaultLayouts[device.name]!;
        expect(tiles, isNotEmpty);
        expect(tiles.map((t) => t.widget).toSet().length, tiles.length);
        for (final t in tiles) {
          expect(ids, contains(t.widget));
        }
      }
    });

    test('template items use known types', () async {
      final rules =
          await RulesLoader((path) => File(path).readAsString()).load();
      for (final template in rules.widgetTemplates) {
        for (final item in template.items) {
          expect(itemTypes, contains(item.type), reason: template.id);
        }
      }
    });

    test('stunt lists are loaded', () async {
      final rules =
          await RulesLoader((path) => File(path).readAsString()).load();
      expect(rules.combatStunts, isNotEmpty);
      expect(rules.explorationStunts, isNotEmpty);
      expect(rules.roleplayingStunts, isNotEmpty);
      expect(rules.magic.standardStunts, isNotEmpty);
    });
  });

  group('DamageRoll', () {
    test('rolls the dice and adds the flat bonus', () {
      final roll = DamageRoll.tryRoll('2d6+3', Random(1))!;
      expect(roll.dice.length, 2);
      expect(roll.flat, 3);
      expect(roll.total, roll.dice[0] + roll.dice[1] + 3);
    });

    test('negative bonus never gives less than 0', () {
      final roll = const DamageRoll([1], -3);
      expect(roll.total, 0);
      expect(DamageRoll.tryRoll('1d6-1', Random(2))!.flat, -1);
    });

    test('text that is not dice gives null; a die can be changed', () {
      expect(DamageRoll.tryRoll('special', Random(1)), isNull);
      final changed = const DamageRoll([1, 2], 1).withDie(0, 6);
      expect(changed.total, 9);
    });
  });
}
