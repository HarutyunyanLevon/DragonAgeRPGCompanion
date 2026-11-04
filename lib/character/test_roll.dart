import 'dart:math';

/// One roll of three six-sided dice: two normal dice and the Dragon Die
/// (the last one). Casting rolls and other tests use it.
class TestRoll {
  const TestRoll(this.dice);

  /// Rolls three dice. Tests pass a seeded [Random] to get a known roll.
  factory TestRoll.roll(Random random) =>
      TestRoll([for (var i = 0; i < 3; i++) random.nextInt(6) + 1]);

  final List<int> dice;

  int get dragonDie => dice[2];
  int get sum => dice[0] + dice[1] + dice[2];

  /// Doubles: two of the three dice show the same number.
  bool get hasDoubles =>
      dice[0] == dice[1] || dice[0] == dice[2] || dice[1] == dice[2];

  /// The test total: the dice plus the ability and focus [bonus].
  int total(int bonus) => sum + bonus;
}
