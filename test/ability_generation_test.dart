import 'dart:io';
import 'dart:math';

import 'package:dragon_age_companion/features/create/ability_generation.dart';
import 'package:dragon_age_companion/rules/models/backgrounds.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BackgroundsFile file;

  setUpAll(() async {
    file = await RulesLoader((path) => File(path).readAsString())
        .loadBackgrounds();
  });

  test('buy method data is read from backgrounds.json', () {
    expect(file.buyMethod.points, 10);
    expect(file.buyMethod.maxPerAbility, 3);
  });

  test('the rules allow start scores from -2 to 4', () {
    expect(file.minScore, -2);
    expect(file.maxScore, 4);
  });

  group('roll', () {
    test('gives every ability a start score between -2 and 4', () {
      final generation =
          const AbilityGeneration().rolled(Random(7), file);
      expect(generation.scores.keys, file.abilities);
      expect(generation.scores.values, everyElement(inInclusiveRange(-2, 4)));
      expect(generation.isComplete(file), isTrue);
    });

    test('allows exactly one swap', () {
      const start = AbilityGeneration(
        pool: [1, 2, 3, 4, 0, 0, 1, 1],
        scores: {'communication': 1, 'constitution': 2},
      );
      expect(start.canSwap, isTrue);

      final swapped = start.swapped('communication', 'constitution');
      expect(swapped.scores['communication'], 2);
      expect(swapped.scores['constitution'], 1);
      expect(swapped.canSwap, isFalse);
    });
  });

  group('arrange', () {
    const rolled = AbilityGeneration(
      method: AbilityMethod.arrange,
      pool: [3, 2, 2, 1, 1, 0, 0, -1],
    );

    test('rolling keeps the scores in the pool, unassigned', () {
      final generation =
          const AbilityGeneration(method: AbilityMethod.arrange)
              .rolled(Random(3), file);
      expect(generation.pool.length, 8);
      expect(generation.scores, isEmpty);
      expect(generation.isComplete(file), isFalse);
    });

    test('an assigned score is no longer offered to other abilities', () {
      final generation = rolled.assigned('magic', 2);
      expect(generation.unassigned, [3, 2, 1, 1, 0, 0, -1]);
      // Each value once, even if it was rolled twice.
      expect(generation.optionsFor('strength'), [3, 2, 1, 0, -1]);
      expect(generation.optionsFor('magic'), [3, 2, 1, 0, -1]);
    });

    test('rolled scores are shown with the taken ones marked', () {
      final generation = rolled.assigned('magic', 2).assigned('cunning', 0);
      expect(generation.poolChips.map((c) => c.score), [3, 2, 2, 1, 1, 0, 0, -1]);
      expect(generation.poolChips.map((c) => c.used),
          [false, true, false, false, false, true, false, false]);
    });
  });

  group('manual', () {
    test('typed scores are kept, an empty field clears the score', () {
      var generation = const AbilityGeneration(method: AbilityMethod.manual);
      generation = generation.entered('magic', 3).entered('strength', -1);
      expect(generation.scores, {'magic': 3, 'strength': -1});
      expect(generation.entered('magic', null).scores, {'strength': -1});
      expect(generation.isComplete(file), isFalse);
    });

    test('scores outside the rules are listed', () {
      final generation = const AbilityGeneration(method: AbilityMethod.manual)
          .entered('magic', 5)
          .entered('strength', -3)
          .entered('cunning', 4)
          .entered('dexterity', -2);
      expect(generation.outOfRange(file), ['magic', 'strength']);
    });
  });

  group('buy', () {
    const buy = AbilityGeneration(method: AbilityMethod.buy);

    test('starts with all points to spend', () {
      expect(buy.pointsLeft(file.buyMethod), 10);
      expect(buy.isComplete(file), isFalse);
    });

    test('is limited per ability and by the points', () {
      var generation = buy;
      for (var i = 0; i < 3; i++) {
        generation = generation.adjusted('magic', 1);
      }
      expect(generation.canIncrease('magic', file.buyMethod), isFalse);
      expect(generation.canIncrease('strength', file.buyMethod), isTrue);
      expect(generation.canDecrease('strength'), isFalse);
    });

    test('is complete when all points are spent', () {
      var generation = buy;
      for (final ability in ['magic', 'cunning', 'willpower']) {
        for (var i = 0; i < 3; i++) {
          generation = generation.adjusted(ability, 1);
        }
      }
      expect(generation.isComplete(file), isFalse);
      generation = generation.adjusted('strength', 1);
      expect(generation.pointsLeft(file.buyMethod), 0);
      expect(generation.isComplete(file), isTrue);
      expect(generation.canIncrease('strength', file.buyMethod), isFalse);
    });
  });
}
