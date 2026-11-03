import 'dart:math';

import '../../rules/rules_data.dart';
import '../../shared/money.dart';

/// Wizard steps 4b and 4c: the weapons picked, the starting silver roll and
/// the things bought with it. Immutable: every change returns a new object.
/// Stored as rules ids.
class GearChoices {
  const GearChoices({
    this.weaponIds = const [],
    this.silverRoll,
    this.bought = const [],
  });

  final List<String> weaponIds;

  /// The 3d6 total (3 to 18), once rolled or entered.
  final int? silverRoll;

  /// Catalog ids of what was bought, one entry per piece (so buying two
  /// arrow bundles lists `arrows-20` twice).
  final List<String> bought;

  GearChoices withWeapons(List<String> weaponIds) =>
      GearChoices(weaponIds: weaponIds, silverRoll: silverRoll, bought: bought);

  GearChoices withSilverRoll(int roll) =>
      GearChoices(weaponIds: weaponIds, silverRoll: roll, bought: bought);

  GearChoices buy(String id) => GearChoices(
      weaponIds: weaponIds, silverRoll: silverRoll, bought: [...bought, id]);

  /// Returns one piece of [id] (the money comes back).
  GearChoices refund(String id) {
    final index = bought.lastIndexOf(id);
    if (index == -1) return this;
    return GearChoices(
      weaponIds: weaponIds,
      silverRoll: silverRoll,
      bought: [...bought.sublist(0, index), ...bought.sublist(index + 1)],
    );
  }

  int count(String id) => bought.where((b) => b == id).length;

  /// All the starting silver, in copper (0 before the roll).
  int startingCopper(RulesData rules) {
    final roll = silverRoll;
    if (roll == null) return 0;
    final silver = rules.classes.startingGear.silver;
    return (silver.base + roll) * copperPerSilver;
  }

  int spentCopper(RulesData rules) => bought.fold(
      0, (sum, id) => sum + rules.catalogEntry(id).costCp);

  /// What is left to spend. Never below 0: a purchase the player confirmed
  /// although it was too expensive leaves nothing, not a debt.
  int leftCopper(RulesData rules) =>
      max(0, startingCopper(rules) - spentCopper(rules));

  bool canAfford(RulesData rules, String id) =>
      rules.catalogEntry(id).costCp <= leftCopper(rules);
}
