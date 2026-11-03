import 'dart:math';

import '../../rules/models/backgrounds.dart';
import '../../rules/models/classes.dart';

/// How the two table results are made: rolled (or picked) or bought.
enum BenefitMode { roll, buy }

/// Why a table row breaks the rules. Rolling skips such rows (re-roll);
/// picking or buying one asks "Proceed anyway?".
enum BenefitConflict {
  sameRow, // the other result is this row already
  alreadyOwned, // the character already has this focus / language / group
  abilityCap, // the ability would go above the highest start score
  overBudget, // buying: not enough advancements left
}

int roll2d6(Random random) => random.nextInt(6) + random.nextInt(6) + 2;

/// What the benefit rules need to know about the character made so far.
/// Rebuilt from the draft whenever it changes; nothing is stored in here.
class BenefitFacts {
  const BenefitFacts({
    required this.background,
    required this.race,
    required this.classRules,
    required this.startScores,
    required this.maxScore,
    required this.buy,
  });

  final Background background;
  final String race;
  final ClassRules classRules;

  /// Step 2 scores (before the background's +1). Missing = 0.
  final Map<String, int> startScores;

  /// Highest start score the rules allow (4).
  final int maxScore;
  final BuyMethod buy;

  /// The 2d6 table of this background and race. Rows are told apart by index.
  List<BackgroundTableRow> get table => background.tableFor(race);

  /// Index of the table row that a 2d6 [roll] lands on.
  int rowForRoll(int roll) =>
      table.indexWhere((r) => roll >= r.min && roll <= r.max);

  /// What a row gives. A weapon group the class already has turns into the
  /// focus the table names as its replacement (Orlesian Exile, Light Blades).
  TableResult resultAt(int row) {
    final result = table[row].result;
    final replacement = result.ifClassHasGroup;
    if (replacement != null &&
        classRules.weaponGroups.fixed.contains(result.group)) {
      return TableResult(
        type: 'focus',
        ability: replacement.ability,
        focus: replacement.focus,
      );
    }
    return result;
  }

  /// Buying: an ability increase costs more than anything else.
  int costOf(int row) => resultAt(row).type == 'ability'
      ? buy.abilityIncreaseCost
      : buy.otherBenefitCost;
}

/// Step 3: what the background gives besides its fixed +1 ability. Immutable:
/// every change returns a new object. Rows and focuses are stored as indexes
/// into the background's lists, so nothing here depends on object identity.
class BackgroundBenefits {
  const BackgroundBenefits({
    this.mode = BenefitMode.roll,
    this.focusIndex,
    this.languages = const [],
    this.rolled = const [null, null],
    this.bought = const {},
  });

  final BenefitMode mode;

  /// Which of background.focusChoices was picked.
  final int? focusIndex;

  /// Languages picked from background.languageChoice.
  final List<String> languages;

  /// Roll mode: the table row of each of the two results (null = not made yet).
  /// A result may come from a roll or from picking the row.
  final List<int?> rolled;

  /// Buy mode: the table rows bought.
  final Set<int> bought;

  // ---- changing

  BackgroundBenefits _copyWith({
    int? focusIndex,
    List<String>? languages,
    List<int?>? rolled,
    Set<int>? bought,
  }) =>
      BackgroundBenefits(
        mode: mode,
        focusIndex: focusIndex ?? this.focusIndex,
        languages: languages ?? this.languages,
        rolled: rolled ?? this.rolled,
        bought: bought ?? this.bought,
      );

  /// Switching between roll and buy starts the table results over.
  BackgroundBenefits changeMode(BenefitMode mode) => BackgroundBenefits(
        mode: mode,
        focusIndex: focusIndex,
        languages: languages,
      );

  BackgroundBenefits withFocus(int index) => _copyWith(focusIndex: index);

  BackgroundBenefits withLanguages(List<String> languages) =>
      _copyWith(languages: languages);

  /// Puts table [row] into result [slot] (0 or 1).
  BackgroundBenefits withRow(int slot, int row) =>
      _copyWith(rolled: [...rolled]..[slot] = row);

  /// Buys [row], or gives it back when it was bought already.
  BackgroundBenefits toggleBought(int row) => _copyWith(
        bought: bought.contains(row)
            ? ({...bought}..remove(row))
            : {...bought, row},
      );

  /// Rolls 2d6 for [slot]. A row that breaks a rule is skipped (re-rolled),
  /// which also re-rolls duplicates, as the book says.
  BackgroundBenefits rollSlot(BenefitFacts facts, int slot, Random random) {
    final rows = [for (var i = 0; i < facts.table.length; i++) i];
    final free =
        rows.where((row) => conflictFor(facts, row, slot: slot) == null);
    // Every row blocked (cannot really happen): any row will do.
    final allowed = free.isEmpty ? rows : free.toList();

    int row;
    do {
      row = facts.rowForRoll(roll2d6(random));
    } while (!allowed.contains(row));
    return withRow(slot, row);
  }

  // ---- reading

  /// Table rows taken so far in the current mode.
  List<int> get chosenRows => mode == BenefitMode.roll
      ? [for (final row in rolled) if (row != null) row]
      : bought.toList();

  int pointsLeft(BenefitFacts facts) =>
      facts.buy.backgroundBenefitPoints -
      bought.fold(0, (sum, row) => sum + facts.costOf(row));

  /// Everything step 3 asks for has an answer.
  bool isComplete(BenefitFacts facts) =>
      focusIndex != null &&
      languages.length == (facts.background.languageChoice?.pick ?? 0) &&
      (mode == BenefitMode.roll
          ? !rolled.contains(null)
          : pointsLeft(facts) <= 0);

  /// Why taking table [row] breaks a rule, or null if it does not.
  /// [slot] is the result being replaced (roll mode), so it is not compared
  /// with itself.
  BenefitConflict? conflictFor(BenefitFacts facts, int row, {int? slot}) {
    final others = _otherRows(slot);
    if (others.contains(row)) return BenefitConflict.sameRow;

    final result = facts.resultAt(row);
    final otherResults = [for (final other in others) facts.resultAt(other)];

    if (result.type != 'ability' &&
        _ownedKeys(facts, otherResults).contains(_key(result))) {
      return BenefitConflict.alreadyOwned;
    }
    if (result.type == 'ability' &&
        _abilityTotal(facts, result.ability!, otherResults) + 1 >
            facts.maxScore) {
      return BenefitConflict.abilityCap;
    }
    if (mode == BenefitMode.buy && facts.costOf(row) > pointsLeft(facts)) {
      return BenefitConflict.overBudget;
    }
    return null;
  }

  /// The rows taken apart from the one in [slot].
  List<int> _otherRows(int? slot) => mode == BenefitMode.buy
      ? bought.toList()
      : [
          for (var i = 0; i < rolled.length; i++)
            if (i != slot && rolled[i] != null) rolled[i]!,
        ];

  /// One text per thing a result gives, so "already have it" is a set lookup.
  String _key(TableResult r) => switch (r.type) {
        'ability' => 'ability:${r.ability}',
        'focus' => 'focus:${r.ability}:${r.focus}',
        'language' => 'language:${r.language}',
        _ => 'group:${r.group}',
      };

  /// What the character has already, as [_key] texts: the background's
  /// choices, the class's weapon groups and the [others] results.
  Set<String> _ownedKeys(BenefitFacts facts, List<TableResult> others) {
    final index = focusIndex;
    final focus = index == null ? null : facts.background.focusChoices[index];
    return {
      if (focus != null) 'focus:${focus.ability}:${focus.focus}',
      for (final language in [...facts.background.languages, ...languages])
        'language:$language',
      for (final group in facts.classRules.weaponGroups.fixed) 'group:$group',
      for (final other in others)
        if (other.type != 'ability') _key(other),
    };
  }

  /// [ability] after step 2, the background's +1 and the [others] results.
  int _abilityTotal(
      BenefitFacts facts, String ability, List<TableResult> others) {
    final backgroundBonus = ability == facts.background.abilityBonus ? 1 : 0;
    final fromResults =
        others.where((r) => r.type == 'ability' && r.ability == ability).length;
    return (facts.startScores[ability] ?? 0) + backgroundBonus + fromResults;
  }
}
