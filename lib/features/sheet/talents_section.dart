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

/// Racial traits, talents and specializations. Talents show the degree
/// reached (tap a row to read all three degrees); traits show "Racial trait".
/// Traits and talents share one box.
class TalentsSection extends StatelessWidget {
  const TalentsSection({
    super.key,
    required this.character,
    required this.rules,
    required this.filter,
    this.showTitle = true,
  });

  final Character character;
  final RulesData rules;
  final SheetFilter filter;

  /// The Play tab's widget has its own title.
  final bool showTitle;

  static List<String> _traits(
          Character character, RulesData rules, SheetFilter filter) =>
      [
        for (final id in character.traitIds)
          if (filter.matches(traitTexts(rules, id))) id
      ];

  static List<DegreeEntry> _talents(
          Character character, RulesData rules, SheetFilter filter) =>
      [
        for (final e in character.talents)
          if (filter.matches(talentTexts(rules.talents.talentById(e.id)))) e
      ];

  static List<DegreeEntry> _specializations(
          Character character, RulesData rules, SheetFilter filter) =>
      [
        for (final e in character.specializations)
          if (filter.matches(specializationTexts(
              rules.specializations.specializationById(e.id))))
            e
      ];

  static bool hasMatches(
          Character character, RulesData rules, SheetFilter filter) =>
      _traits(character, rules, filter).isNotEmpty ||
      _talents(character, rules, filter).isNotEmpty ||
      _specializations(character, rules, filter).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final traits = _traits(character, rules, filter);
    final talents = _talents(character, rules, filter);
    final specializations = _specializations(character, rules, filter);
    if (traits.isEmpty && talents.isEmpty && specializations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showTitle) SectionTitle(l10n.sectionTalents),
      if (traits.isNotEmpty || talents.isNotEmpty)
        SheetBox(children: [
          for (final id in traits)
            InfoRow(
              title: displayName(id),
              value: l10n.trait,
              child: Text(rules.backgrounds.racialTraits[id] ?? ''),
            ),
          for (final entry in talents)
            InfoRow(
              title: rules.talents.talentById(entry.id).name,
              value: degreeName(l10n, entry.degree),
              child: TalentInfo(
                rules: rules,
                talent: rules.talents.talentById(entry.id),
                degree: entry.degree,
              ),
            ),
        ]),
      if (specializations.isNotEmpty) ...[
        SubsectionTitle(l10n.specializations),
        SheetBox(children: [
          for (final entry in specializations)
            InfoRow(
              title: rules.specializations.specializationById(entry.id).name,
              value: degreeName(l10n, entry.degree),
              child: SpecializationInfo(
                rules: rules,
                specialization:
                    rules.specializations.specializationById(entry.id),
              ),
            ),
        ]),
      ],
    ]);
  }
}
