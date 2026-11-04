import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/sheet_box.dart';
import '../../shared/stat_tiles.dart';
import '../level_up/level_up_bar.dart';

/// The top of the sheet: name, race, class, level, background, experience
/// with the level-up buttons, Health and Mana.
class HeaderBlock extends StatelessWidget {
  const HeaderBlock({super.key, required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = character;

    return SheetBox(
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(l10n.characterLine(displayName(c.race),
              displayName(c.classId), c.level, displayName(c.backgroundId))),
        ),
        LevelUpBar(character: c, rules: rules),
        StatTiles(tiles: [
          StatTile(label: l10n.health, value: '${c.health} / ${c.maxHealth}'),
          if (c.maxMana > 0)
            StatTile(label: l10n.mana, value: '${c.mana} / ${c.maxMana}'),
        ]),
      ],
    );
  }
}
