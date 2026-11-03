import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/form_widgets.dart';
import '../../shared/info_row.dart';
import '../../shared/sheet_box.dart';
import '../create/rule_info.dart';
import 'sheet_filter.dart';

/// Talents and specializations with the degree reached. Tap a row to read
/// all three degrees.
class TalentsSection extends StatelessWidget {
  const TalentsSection({
    super.key,
    required this.character,
    required this.rules,
    required this.filter,
  });

  final Character character;
  final RulesData rules;
  final SheetFilter filter;

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
      _talents(character, rules, filter).isNotEmpty ||
      _specializations(character, rules, filter).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final talents = _talents(character, rules, filter);
    final specializations = _specializations(character, rules, filter);
    if (talents.isEmpty && specializations.isEmpty) {
      return const SizedBox.shrink();
    }

    String degreeName(int degree) => [
          l10n.degreeNameNovice,
          l10n.degreeNameJourneyman,
          l10n.degreeNameMaster,
        ][degree - 1];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l10n.sectionTalents),
      if (talents.isNotEmpty)
        SheetBox(children: [
          for (final entry in talents)
            InfoRow(
              title: rules.talents.talentById(entry.id).name,
              value: degreeName(entry.degree),
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
              value: degreeName(entry.degree),
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
