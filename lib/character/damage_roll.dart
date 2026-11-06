import 'dart:math';

/// One line of dice shown under a roll: a [label] ("Damage", "Healing") and
/// the dice [formula] ("2d6+3").
class DiceLine {
  const DiceLine(this.label, this.formula);

  final String label;
  final String formula;
}

/// A damage roll such as "2d6+3": the dice and the flat bonus.
class DamageRoll {
  const DamageRoll(this.dice, this.flat);

  /// Rolls [formula] ("2d6", "1d6+2", "1d6-1"). Null when it is not dice text.
  /// All dice in the game are six-sided.
  static DamageRoll? tryRoll(String formula, Random random) {
    final match = RegExp(r'^(\d+)d6([+-]\d+)?$').firstMatch(formula.trim());
    if (match == null) return null;
    final count = int.parse(match.group(1)!);
    return DamageRoll(
      [for (var i = 0; i < count; i++) random.nextInt(6) + 1],
      int.parse(match.group(2) ?? '0'),
    );
  }

  final List<int> dice;
  final int flat;

  /// Never below 0.
  int get total => max(0, dice.fold(0, (sum, die) => sum + die) + flat);

  /// The same roll with one die changed (the player typed the real value).
  DamageRoll withDie(int index, int value) => DamageRoll(
        [for (var i = 0; i < dice.length; i++) i == index ? value : dice[i]],
        flat,
      );
}
