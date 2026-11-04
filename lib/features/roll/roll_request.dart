import 'package:flutter/widgets.dart';

import '../../character/test_roll.dart';

/// Which stunts the roll sheet offers when the roll has doubles.
enum StuntSet {
  /// Attack rolls.
  combat,

  /// Casting rolls.
  magic,

  /// Any other test: the player picks combat, exploration or roleplaying.
  test,
}

/// What a finished roll came to. Handed to [RollRequest.extras].
class RollOutcome {
  const RollOutcome({required this.roll, required this.success});

  final TestRoll roll;
  final bool success;
}

/// Everything the roll sheet needs to roll one test (and, for a weapon, its
/// damage). Build one wherever something can be rolled and pass it to
/// `showRoll`.
class RollRequest {
  const RollRequest({
    required this.title,
    required this.bonus,
    this.tn = 11,
    this.stunts = StuntSet.test,
    this.damage,
    this.info = const [],
    this.extras,
    this.onUndo,
  });

  /// "Strength (Climbing)", a weapon or a spell name.
  final String title;

  /// Ability plus focus.
  final int bonus;

  /// Target number to start with (11 is an average test). The sheet can change it.
  final int tn;
  final StuntSet stunts;

  /// Weapons: damage dice such as "2d6+3", rolled together with the attack.
  final String? damage;

  /// Lines shown under the title.
  final List<String> info;

  /// Something below the stunts that depends on the roll (the spell mishap
  /// helper). It starts over whenever the dice change.
  final Widget Function(BuildContext context, RollOutcome outcome)? extras;

  /// Gives something back (the mana of a cast). Shows an Undo button; the
  /// sheet closes after it.
  final Future<void> Function()? onUndo;
}
