import 'dart:math';

import '../../rules/models/backgrounds.dart';

/// The three ways the book offers to make starting abilities.
enum AbilityMethod {
  roll, // 3d6 per ability in sheet order, then swap any two once
  arrange, // roll eight scores, give each to the ability you like
  buy, // spend points, +1 each, limited per ability
  manual, // type scores rolled somewhere else
}

int roll3d6(Random random) =>
    random.nextInt(6) + random.nextInt(6) + random.nextInt(6) + 3;

/// Where the player is in making the abilities. Immutable: every change
/// returns a new object. Scores here are the start scores, before the
/// background's +1 is added.
class AbilityGeneration {
  const AbilityGeneration({
    this.method = AbilityMethod.roll,
    this.pool = const [],
    this.scores = const {},
    this.swapUsed = false,
  });

  final AbilityMethod method;

  /// The scores that were rolled (roll and arrange).
  final List<int> pool;

  /// Ability id -> start score. Missing = not given a score yet.
  final Map<String, int> scores;

  final bool swapUsed;

  bool get hasRolled => pool.isNotEmpty;

  /// Starts over with another method.
  AbilityGeneration changeMethod(AbilityMethod method) =>
      AbilityGeneration(method: method);

  bool isComplete(BackgroundsFile file) => method == AbilityMethod.buy
      ? pointsLeft(file.buyMethod) == 0
      : scores.length == file.abilities.length;

  /// Rolls 3d6 per ability. With [AbilityMethod.roll] the scores go to the
  /// abilities in sheet order; with [AbilityMethod.arrange] they wait in the pool.
  AbilityGeneration rolled(Random random, BackgroundsFile file) {
    final pool = [
      for (final _ in file.abilities) file.scoreForRoll(roll3d6(random)),
    ];
    return AbilityGeneration(
      method: method,
      pool: pool,
      scores: method == AbilityMethod.roll
          ? {
              for (var i = 0; i < pool.length; i++) file.abilities[i]: pool[i],
            }
          : {},
    );
  }

  // ---- roll: one swap

  bool get canSwap => method == AbilityMethod.roll && hasRolled && !swapUsed;

  AbilityGeneration swapped(String a, String b) => AbilityGeneration(
        method: method,
        pool: pool,
        scores: {...scores, a: scores[b]!, b: scores[a]!},
        swapUsed: true,
      );

  // ---- arrange: give rolled scores to abilities

  /// Rolled scores that no ability has taken yet.
  List<int> get unassigned {
    final left = [...pool];
    for (final score in scores.values) {
      left.remove(score);
    }
    return left;
  }

  /// What the dropdown of [ability] offers: free scores plus its own, each
  /// value once (a dropdown cannot list the same value twice).
  List<int> optionsFor(String ability) {
    final own = scores[ability];
    return {...unassigned, if (own != null) own}.toList()
      ..sort((a, b) => b.compareTo(a));
  }

  /// The rolled scores, best first, with whether an ability has taken each.
  List<({int score, bool used})> get poolChips {
    final taken = [...scores.values];
    return [
      for (final score in [...pool]..sort((a, b) => b.compareTo(a)))
        (score: score, used: taken.remove(score)),
    ];
  }

  AbilityGeneration assigned(String ability, int score) => AbilityGeneration(
        method: method,
        pool: pool,
        scores: {...scores, ability: score},
      );

  // ---- manual: scores typed in

  /// Sets the typed score of [ability]; null (empty field) clears it.
  AbilityGeneration entered(String ability, int? score) {
    final next = {...scores};
    if (score == null) {
      next.remove(ability);
    } else {
      next[ability] = score;
    }
    return AbilityGeneration(method: method, scores: next);
  }

  /// Abilities whose score the rules do not allow (any method, but only
  /// typed-in scores can really be out of range).
  List<String> outOfRange(BackgroundsFile file) => [
        for (final entry in scores.entries)
          if (entry.value < file.minScore || entry.value > file.maxScore)
            entry.key,
      ];

  // ---- buy: spend points

  int pointsLeft(BuyMethod buy) =>
      buy.points - scores.values.fold(0, (sum, score) => sum + score);

  bool canIncrease(String ability, BuyMethod buy) =>
      (scores[ability] ?? 0) < buy.maxPerAbility && pointsLeft(buy) > 0;

  bool canDecrease(String ability) => (scores[ability] ?? 0) > 0;

  AbilityGeneration adjusted(String ability, int change) => AbilityGeneration(
        method: method,
        scores: {...scores, ability: (scores[ability] ?? 0) + change},
      );
}
