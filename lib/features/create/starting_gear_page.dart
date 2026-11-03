import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../character/starting_equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/form_widgets.dart';
import '../../shared/info_row.dart';
import '../../shared/row_picker.dart';
import 'character_builder.dart';
import 'character_draft.dart';
import 'rule_info.dart';
import 'shop_page.dart';

/// Wizard step 4b of 4: pick the starting weapons; the rest of the class's
/// gear (armor, shield, ammunition, basics) is given automatically and
/// listed so the player can read about it.
class StartingGearPage extends ConsumerWidget {
  const StartingGearPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final draft = ref.watch(characterDraftProvider);
    final notifier = ref.read(characterDraftProvider.notifier);

    final classRules = rules.classes.classById(draft.classId!);
    final groups = finalWeaponGroups(draft, rules);
    final count = startingWeaponCount(classRules, groups, rules);
    final picked = draft.gearChoices.weaponIds;
    final items = draftStartingItems(draft, rules);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(4, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(l10n.startingGearTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (count > 0) ...[
          SectionTitle(l10n.startingWeaponsTitle(count)),
          RowPicker(
            options: [
              for (final id in startingWeaponChoices(groups, rules))
                (id, rules.weaponById(id)!.name),
            ],
            picked: picked,
            limit: count,
            onChange: (ids) =>
                notifier.setGearChoices(draft.gearChoices.withWeapons(ids)),
            describe: (id) => ItemInfo(
                rules: rules, itemId: id, name: rules.weaponById(id)!.name),
          ),
          Text(l10n.pickedOf(picked.length, count)),
          const SizedBox(height: 24),
        ],
        SectionTitle(l10n.youGet),
        for (final item in items)
          // Basics like a backpack are not in the price list: nothing to read.
          item.itemId == null
              ? ListTile(title: Text(item.name))
              : InfoRow(
                  title: item.name,
                  child: ItemInfo(
                      rules: rules, itemId: item.itemId, name: item.name),
                ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: picked.length == count
              ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const ShopPage(),
                  ))
              : null,
          child: Text(l10n.next),
        ),
      ]),
    );
  }
}
