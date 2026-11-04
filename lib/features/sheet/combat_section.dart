import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../character/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/gear.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import '../../shared/info_row.dart';
import '../../shared/sheet_box.dart';
import '../../shared/stat_tiles.dart';
import '../create/rule_info.dart';
import 'sheet_filter.dart';

/// Speed, Defense, Armor and Penalty, Move / Charge / Run, the equipped
/// weapons, weapon groups and languages. Tap a tile or row to read how the
/// number is made or what the thing is.
class CombatSection extends StatelessWidget {
  const CombatSection({
    super.key,
    required this.character,
    required this.rules,
    required this.filter,
  });

  final Character character;
  final RulesData rules;
  final SheetFilter filter;

  /// False when the search hides everything in this section.
  static bool hasMatches(AppLocalizations l10n, Character character,
          RulesData rules, SheetFilter filter) =>
      combatStatTiles(l10n, character, rules, filter).isNotEmpty ||
      moveTiles(l10n, character, rules, filter).isNotEmpty ||
      _weapons(character, rules, filter).isNotEmpty ||
      _groups(character, filter).isNotEmpty ||
      _languages(character, filter).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = combatStatTiles(l10n, character, rules, filter);
    final moves = moveTiles(l10n, character, rules, filter);
    final weapons = _weapons(character, rules, filter);
    final groups = _groups(character, filter);
    final languages = _languages(character, filter);

    if (!hasMatches(l10n, character, rules, filter)) {
      return const SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l10n.sectionCombat),
      if (stats.isNotEmpty || moves.isNotEmpty)
        SheetBox(children: [
          if (stats.isNotEmpty) StatTiles(tiles: stats),
          if (moves.isNotEmpty) StatTiles(tiles: moves),
        ]),
      if (weapons.isNotEmpty) ...[
        SubsectionTitle(l10n.weapons),
        SheetBox(children: [
          for (final weapon in weapons) _weaponRow(l10n, weapon),
        ]),
      ],
      if (groups.isNotEmpty) ...[
        SubsectionTitle(l10n.weaponGroups),
        SheetBox(children: [
          for (final group in groups)
            InfoRow(
              title: displayName(group),
              child: WeaponGroupInfo(rules: rules, group: group),
            ),
        ]),
      ],
      if (languages.isNotEmpty) ...[
        SubsectionTitle(l10n.languages),
        SheetBox(children: [
          for (final language in languages)
            InfoRow(
              title: displayName(language),
              child: LanguageInfo(rules: rules, language: language),
            ),
        ]),
      ],
    ]);
  }

  /// An equipped weapon: attack and damage (and range for missile weapons).
  Widget _weaponRow(AppLocalizations l10n, Weapon weapon) {
    final numbers = weaponNumbers(character, weapon, rules);
    final range = weapon.range;
    final lines = [
      l10n.weaponNumbersLine(signed(numbers.attack), numbers.damage),
      if (range != null) l10n.rangeLine(range.short, range.long, range.reload),
      if (!numbers.trained) l10n.untrainedWeapon,
    ];

    return InfoRow(
      title: weapon.name,
      subtitle: lines.join('\n'),
      child: ItemInfo(rules: rules, itemId: weapon.id, name: weapon.name),
    );
  }
}

// What the section shows, after the search. Used by build, hasMatches and the
// Play tab's combat widget.

List<StatTile> combatStatTiles(AppLocalizations l10n, Character character,
    RulesData rules, SheetFilter filter) {
  final n = combatNumbers(character, rules);
  final tiles = [
    StatTile(
      label: l10n.speed,
      value: '${n.speed}',
      info: CombatStatInfo(stat: CombatStat.speed, numbers: n),
    ),
    StatTile(
      label: l10n.defense,
      value: '${n.defense}',
      info: CombatStatInfo(stat: CombatStat.defense, numbers: n),
    ),
    StatTile(
      label: l10n.armorShort,
      value: '${n.armorRating}',
      info: CombatStatInfo(stat: CombatStat.armorRating, numbers: n),
    ),
    StatTile(
      label: l10n.penaltyShort,
      value: '${n.armorPenalty}',
      info: Text(l10n.armorPenaltyRule),
    ),
  ];
  return [for (final t in tiles) if (filter.matches([t.label])) t];
}

/// Move, Charge and Run in yards, from Speed.
List<StatTile> moveTiles(AppLocalizations l10n, Character character,
    RulesData rules, SheetFilter filter) {
  final speed = combatNumbers(character, rules).speed;
  final tiles = [
    StatTile(
        label: l10n.move, value: '$speed', info: Text(l10n.moveRule)),
    StatTile(
        label: l10n.charge, value: '${speed ~/ 2}', info: Text(l10n.chargeRule)),
    StatTile(label: l10n.run, value: '${speed * 2}', info: Text(l10n.runRule)),
  ];
  return [for (final t in tiles) if (filter.matches([t.label])) t];
}

List<Weapon> _weapons(
    Character character, RulesData rules, SheetFilter filter) {
  return [
    for (final item in character.inventory)
      if (item.equipped && rules.weaponById(item.itemId) != null)
        if (filter.matches(itemTexts(rules, item))) rules.weaponById(item.itemId)!,
  ];
}

List<String> _groups(Character character, SheetFilter filter) =>
    [for (final g in character.weaponGroups) if (filter.matches([displayName(g)])) g];

List<String> _languages(Character character, SheetFilter filter) => [
      for (final l in character.languages)
        if (filter.matches([displayName(l)])) l
    ];
