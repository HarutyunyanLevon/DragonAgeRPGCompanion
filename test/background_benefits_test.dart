import 'dart:io';
import 'dart:math';

import 'package:dragon_age_companion/features/create/background_benefits.dart';
import 'package:dragon_age_companion/rules/models/backgrounds.dart';
import 'package:dragon_age_companion/rules/models/classes.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BackgroundsFile backgrounds;
  late ClassesFile classes;

  setUpAll(() async {
    final loader = RulesLoader((path) => File(path).readAsString());
    backgrounds = await loader.loadBackgrounds();
    classes = await loader.loadClasses();
  });

  BenefitFacts factsFor(
    String backgroundId,
    String race,
    String classId, {
    Map<String, int> startScores = const {},
  }) =>
      BenefitFacts(
        background: backgrounds.backgroundById(backgroundId),
        race: race,
        classRules: classes.classById(classId),
        startScores: startScores,
        maxScore: backgrounds.maxScore,
        buy: backgrounds.buyMethod,
      );

  const none = BackgroundBenefits();

  // Apostate (human) table rows, by index:
  //  0: 2 +1 Constitution      4: 7-8 +1 Magic
  //  1: 3-4 Stamina            5: 9 Riding
  //  2: 5 Self-Discipline      6: 10-11 Deception
  //  3: 6 Healing              7: 12 +1 Cunning
  // Its focus choices: 0 = Natural Lore, 1 = Self-Discipline.
  // (The contexts are made in setUp: the rules are loaded in setUpAll.)

  group('table', () {
    test('a background with one table per race gives the race its own', () {
      final apostate = backgrounds.backgroundById('apostate');
      expect(apostate.tableFor('elf'), same(apostate.tables['elf']));
      expect(apostate.tableFor('human'), same(apostate.tables['human']));
    });

    test('other backgrounds use the shared table', () {
      final exile = backgrounds.backgroundById('orlesian-exile');
      expect(exile.tableFor('human'), same(exile.tables['any']));
    });

    test('a 2d6 roll finds its row', () {
      final facts = factsFor('apostate', 'human', 'mage');
      expect(facts.rowForRoll(2), 0);
      expect(facts.rowForRoll(8), 4);
      expect(facts.rowForRoll(12), 7);
    });

    test('a weapon group the class has turns into the fallback focus', () {
      // Orlesian Exile, rolls 10-11: Light Blades.
      final rogue = factsFor('orlesian-exile', 'human', 'rogue');
      final warrior = factsFor('orlesian-exile', 'human', 'warrior');
      final row = rogue.rowForRoll(10);

      expect(rogue.resultAt(row).type, 'focus');
      expect(rogue.resultAt(row).ability, 'dexterity');
      expect(rogue.resultAt(row).focus, 'light-blades');
      expect(warrior.resultAt(row).type, 'weaponGroup');
      expect(warrior.resultAt(row).group, 'light-blades');
    });
  });

  group('rules', () {
    late BenefitFacts mage;

    setUp(() => mage = factsFor('apostate', 'human', 'mage'));

    test('the other result may not be the same row', () {
      final benefits = none.withRow(0, 3);
      expect(benefits.conflictFor(mage, 3, slot: 1), BenefitConflict.sameRow);
      // Replacing the result in its own slot is fine.
      expect(benefits.conflictFor(mage, 3, slot: 0), isNull);
    });

    test('a focus the background gave already is owned', () {
      final benefits = none.withFocus(1); // Self-Discipline
      expect(benefits.conflictFor(mage, 2), BenefitConflict.alreadyOwned);
      expect(benefits.conflictFor(mage, 3), isNull);
    });

    test('a weapon group of the class is owned', () {
      final rogue = factsFor('apostate', 'elf', 'rogue');
      final elfMage = factsFor('apostate', 'elf', 'mage');
      final bows = rogue.rowForRoll(12);
      expect(none.conflictFor(rogue, bows), BenefitConflict.alreadyOwned);
      expect(none.conflictFor(elfMage, bows), isNull);
    });

    test('a language already picked is owned', () {
      // Apostate (elf), roll 3-4: Speak Elven.
      final elf = factsFor('apostate', 'elf', 'mage');
      final elven = elf.rowForRoll(3);
      expect(none.conflictFor(elf, elven), isNull);
      expect(none.withLanguages(['elven']).conflictFor(elf, elven),
          BenefitConflict.alreadyOwned);
    });

    test('an ability may not go above the highest start score', () {
      final magic = mage.rowForRoll(7); // +1 Magic
      final atCap = factsFor('apostate', 'human', 'mage',
          startScores: {'magic': 4});
      final belowCap = factsFor('apostate', 'human', 'mage',
          startScores: {'magic': 3});
      expect(none.conflictFor(atCap, magic), BenefitConflict.abilityCap);
      expect(none.conflictFor(belowCap, magic), isNull);
    });

    test('the background +1 counts toward the cap', () {
      // Qunari Beresaad gives +1 Strength, and its roll of 12 is +1 Strength.
      const strength = 7;
      final three = factsFor('qunari-beresaad', 'qunari', 'warrior',
          startScores: {'strength': 3}); // 3 + 1 + 1 = 5
      final two = factsFor('qunari-beresaad', 'qunari', 'warrior',
          startScores: {'strength': 2}); // 2 + 1 + 1 = 4
      expect(none.conflictFor(three, strength), BenefitConflict.abilityCap);
      expect(none.conflictFor(two, strength), isNull);
    });
  });

  group('rolling', () {
    late BenefitFacts facts;

    setUp(() => facts = factsFor('apostate', 'human', 'mage'));

    test('never gives the same row twice or a blocked row', () {
      for (var seed = 0; seed < 200; seed++) {
        var benefits = none.withFocus(1);
        benefits = benefits.rollSlot(facts, 0, Random(seed));
        benefits = benefits.rollSlot(facts, 1, Random(seed + 1000));

        expect(benefits.rolled[0], isNot(benefits.rolled[1]));
        expect(benefits.conflictFor(facts, benefits.rolled[0]!, slot: 0), isNull);
        expect(benefits.conflictFor(facts, benefits.rolled[1]!, slot: 1), isNull);
      }
    });

    test('every row can be reached', () {
      final seen = <int>{};
      for (var seed = 0; seed < 500; seed++) {
        seen.add(none.rollSlot(facts, 0, Random(seed)).rolled[0]!);
      }
      expect(seen, {0, 1, 2, 3, 4, 5, 6, 7});
    });
  });

  group('completion', () {
    test('roll mode needs the focus and both results', () {
      final facts = factsFor('apostate', 'human', 'mage');
      expect(none.isComplete(facts), isFalse);
      expect(none.withFocus(0).withRow(0, 1).isComplete(facts), isFalse);
      expect(none.withFocus(0).withRow(0, 1).withRow(1, 2).isComplete(facts),
          isTrue);
    });

    test('a language choice must be made when the background has one', () {
      final facts = factsFor('waking-sea-raider', 'human', 'rogue');
      final almost = none.withFocus(0).withRow(0, 1).withRow(1, 2);
      expect(almost.isComplete(facts), isFalse);
      expect(almost.withLanguages(['antivan']).isComplete(facts), isTrue);
    });

    test('changing the mode keeps the choices, clears the results', () {
      final facts = factsFor('apostate', 'human', 'mage');
      final benefits =
          none.withFocus(0).withRow(0, 1).changeMode(BenefitMode.buy);
      expect(benefits.mode, BenefitMode.buy);
      expect(benefits.focusIndex, 0);
      expect(benefits.chosenRows, isEmpty);
      expect(benefits.pointsLeft(facts), 3);
    });
  });

  group('buying', () {
    late BenefitFacts facts;
    late BackgroundBenefits buying;

    setUp(() {
      facts = factsFor('apostate', 'human', 'mage');
      buying = none.withFocus(0).changeMode(BenefitMode.buy);
    });

    test('an ability increase costs 2, anything else 1', () {
      expect(facts.costOf(4), 2); // +1 Magic
      expect(facts.costOf(1), 1); // Stamina
      expect(buying.toggleBought(4).pointsLeft(facts), 1);
      expect(buying.toggleBought(1).pointsLeft(facts), 2);
    });

    test('a second ability increase does not fit', () {
      final bought = buying.toggleBought(4); // +1 Magic, 1 point left
      expect(bought.conflictFor(facts, 7), BenefitConflict.overBudget);
      expect(bought.conflictFor(facts, 1), isNull);
    });

    test('complete once every advancement is spent', () {
      final bought = buying.toggleBought(4);
      expect(bought.isComplete(facts), isFalse);
      expect(bought.toggleBought(1).isComplete(facts), isTrue);
    });

    test('tapping a bought row gives it back', () {
      final bought = buying.toggleBought(4).toggleBought(4);
      expect(bought.bought, isEmpty);
      expect(bought.pointsLeft(facts), 3);
    });
  });
}
