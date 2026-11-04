import 'dart:io';

import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

// Reads the rules straight from the assets folder (tests run from the project root).
Future<String> readFromDisk(String path) => File(path).readAsString();

void main() {
  final loader = RulesLoader(readFromDisk);

  group('classes.json', () {
    test('has the three classes with 20 levels each', () async {
      final file = await loader.loadClasses();
      expect(file.classes.map((c) => c.id), ['mage', 'rogue', 'warrior']);
      for (final c in file.classes) {
        expect(c.levels.map((l) => l.level), List.generate(20, (i) => i + 1));
      }
    });

    test('xp table maps xp to level', () async {
      final file = await loader.loadClasses();
      expect(file.xpByLevel.length, 20);
      expect(file.levelForXp(0), 1);
      expect(file.levelForXp(1999), 1);
      expect(file.levelForXp(2000), 2);
      expect(file.levelForXp(22000), 10);
      expect(file.levelForXp(999999), 20);
      expect(file.xpForLevel(6), 10000);
    });

    test('advancement cost by rating', () async {
      final file = await loader.loadClasses();
      expect(file.advancementsNeeded(-1), 1);
      expect(file.advancementsNeeded(5), 1);
      expect(file.advancementsNeeded(6), 2);
      expect(file.advancementsNeeded(8), 2);
      expect(file.advancementsNeeded(9), 3);
      expect(file.advancementsNeeded(12), 3);
    });

    test('even levels need a primary ability, odd levels a secondary one',
        () async {
      final mage = (await loader.loadClasses()).classById('mage');
      expect(mage.isAdvancementAllowed(ability: 'magic', level: 2), isTrue);
      expect(mage.isAdvancementAllowed(ability: 'magic', level: 3), isFalse);
      expect(mage.isAdvancementAllowed(ability: 'strength', level: 3), isTrue);
      expect(mage.isAdvancementAllowed(ability: 'strength', level: 4), isFalse);
    });

    test('every class gets each specialization step once', () async {
      final file = await loader.loadClasses();
      for (final c in file.classes) {
        final steps = [
          for (final l in c.levels)
            if (l.specialization != null)
              '${l.level}:${l.specialization!.slot}:${l.specialization!.degree}'
        ];
        expect(steps, [
          '6:6:novice', '8:6:journeyman', '10:6:master',
          '14:14:novice', '16:14:journeyman', '18:14:master',
        ], reason: c.id);
      }
    });
  });

  group('backgrounds.json', () {
    test('score table covers every 3d6 total', () async {
      final file = await loader.loadBackgrounds();
      expect(file.scoreForRoll(3), -2);
      expect(file.scoreForRoll(5), -1);
      expect(file.scoreForRoll(10), 1);
      expect(file.scoreForRoll(18), 4);
      for (var total = 3; total <= 18; total++) {
        file.scoreForRoll(total); // throws if a total has no row
      }
    });

    test('every table covers every 2d6 roll', () async {
      final file = await loader.loadBackgrounds();
      for (final b in file.backgrounds) {
        for (final key in b.tables.keys) {
          for (var roll = 2; roll <= 12; roll++) {
            b.rowForRoll(key, roll); // throws if a roll has no row
          }
        }
      }
    });

    test('every racial trait used by a background has a description', () async {
      final file = await loader.loadBackgrounds();
      for (final b in file.backgrounds) {
        if (b.trait != null) {
          expect(file.racialTraits[b.trait], isNotEmpty, reason: b.id);
        }
      }
    });

    test('references to classes and abilities are valid', () async {
      final classes = await loader.loadClasses();
      final file = await loader.loadBackgrounds();
      final classIds = classes.classes.map((c) => c.id).toSet();
      for (final b in file.backgrounds) {
        expect(classIds.containsAll(b.classes), isTrue, reason: b.id);
        expect(file.abilities, contains(b.abilityBonus), reason: b.id);
      }
    });
  });

  group('core.json', () {
    test('has 80 focuses and every background focus choice exists', () async {
      final focuses = await loader.loadFocuses();
      expect(focuses.length, 80);
      final known = {for (final f in focuses) '${f.ability}/${f.id}'};
      final backgrounds = await loader.loadBackgrounds();
      for (final b in backgrounds.backgrounds) {
        for (final choice in b.focusChoices) {
          expect(known, contains('${choice.ability}/${choice.focus}'),
              reason: b.id);
        }
      }
    });
  });

  group('talents.json', () {
    test('class starting talents exist and belong to the class', () async {
      final classes = await loader.loadClasses();
      final talents = await loader.loadTalents();
      for (final c in classes.classes) {
        for (final id in [
          ...c.startingTalents.fixed,
          ...c.startingTalents.pickFrom
        ]) {
          expect(talents.talentById(id).classes, contains(c.id),
              reason: '${c.id} / $id');
        }
      }
    });

    test('degree text can be looked up by number', () async {
      final talent = (await loader.loadTalents()).talentById('chirurgy');
      expect(talent.degrees.textFor(1), 'Heal is a minor action.');
    });
  });

  test('spells.json loads (skipped until it is copied into assets/rules)',
      () async {
    if (!File('assets/rules/spells.json').existsSync()) {
      markTestSkipped('Copy spells.json from the Project into assets/rules/');
      return;
    }
    final spells = await loader.loadSpells();
    expect(spells.length, greaterThan(100));
    expect(spells.map((s) => s.id), contains('winters-grasp'));
    final full = await loader.load();
    expect(full.spellById('heal').school, 'Creation');
  });
}
