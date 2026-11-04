import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../character/magic.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import 'roll_request.dart';
import 'roll_sheet.dart';

/// Rolls an ability test, with one of the character's focuses if given.
/// "Strength" or "Strength (Climbing)".
Future<void> rollAbility(
  BuildContext context,
  Character character,
  RulesData rules,
  String ability, {
  String? focus,
}) {
  final l10n = AppLocalizations.of(context);
  final name = displayName(ability);

  return showRoll(
    context,
    rules,
    RollRequest(
      title: focus == null ? name : l10n.focusLabel(name, displayName(focus)),
      bonus: focus == null
          ? character.ability(ability)
          : testBonus(character, ability, focus),
    ),
  );
}
