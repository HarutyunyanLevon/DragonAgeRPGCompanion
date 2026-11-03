import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import '../../shared/info_row.dart';
import '../../shared/sheet_box.dart';
import '../create/rule_info.dart';
import 'sheet_filter.dart';

/// The eight abilities, each in a box with its focuses. Tap an ability or a
/// focus to read about it. With a search, an ability shows when it or one of
/// its focuses matches (only the matching focuses then).
class AbilitiesSection extends StatelessWidget {
  const AbilitiesSection({
    super.key,
    required this.character,
    required this.rules,
    required this.filter,
  });

  final Character character;
  final RulesData rules;
  final SheetFilter filter;

  /// The focuses of [ability] to show: all of them when the ability itself
  /// matches, otherwise only the matching ones. Null: hide the ability.
  static List<CharacterFocus>? _visibleFocuses(Character character,
      RulesData rules, SheetFilter filter, String ability) {
    final own = [
      for (final f in character.focuses)
        if (f.ability == ability) f
    ];
    if (filter.matches(abilityTexts(rules, ability))) return own;
    final matching = [
      for (final f in own)
        if (filter.matches([displayName(f.focus)])) f
    ];
    return matching.isEmpty ? null : matching;
  }

  static bool hasMatches(
          Character character, RulesData rules, SheetFilter filter) =>
      rules.backgrounds.abilities.any(
          (a) => _visibleFocuses(character, rules, filter, a) != null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!hasMatches(character, rules, filter)) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l10n.abilities),
      for (final ability in rules.backgrounds.abilities)
        if (_visibleFocuses(character, rules, filter, ability)
            case final focuses?)
          SheetBox(
            header: InfoRow(
              title: displayName(ability),
              value: signed(character.ability(ability)),
              child: AbilityInfo(rules: rules, ability: ability),
            ),
            children: [
              for (final focus in focuses)
                InfoRow(
                  title: displayName(focus.focus),
                  value: signed(focus.bonus),
                  child: FocusInfo(
                      rules: rules, ability: ability, focus: focus.focus),
                ),
            ],
          ),
    ]);
  }
}
