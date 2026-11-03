import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/money.dart';
import '../gear/catalog_browser.dart';
import '../../rules/rules_data.dart';
import 'character_draft.dart';
import 'gear_choices.dart';
import 'health_mana_page.dart';

/// Wizard step 4c of 4: roll (or enter) the starting silver, then spend it.
/// Buying something too expensive is allowed after a "Proceed anyway": the
/// money just stops at 0.
class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  Future<void> _buy(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context);
    final rules = ref.read(rulesProvider).requireValue;
    final gear = ref.read(characterDraftProvider).gearChoices;

    if (!gear.canAfford(rules, id)) {
      final confirmed = await confirm(
        context,
        title: l10n.cannotAfford,
        body: l10n.cannotAffordBody,
        confirmLabel: l10n.proceedAnyway,
      );
      if (!confirmed) return;
    }
    ref.read(characterDraftProvider.notifier).setGearChoices(gear.buy(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final gear = ref.watch(characterDraftProvider).gearChoices;
    final notifier = ref.read(characterDraftProvider.notifier);
    final silver = rules.classes.startingGear.silver;
    final rolled = gear.silverRoll != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.stepOf(4, 4),
                style: Theme.of(context).textTheme.labelLarge),
            Text(l10n.shopTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.startingSilverLine(silver.base, silver.dice)),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(l10n.rollSilver(silver.dice)),
                  onPressed: () => notifier
                      .setGearChoices(gear.withSilverRoll(_roll3d6())),
                ),
                DropdownButton<int>(
                  hint: Text(l10n.diceTotal),
                  value: gear.silverRoll,
                  items: [
                    for (var total = 3; total <= 18; total++)
                      DropdownMenuItem(value: total, child: Text('$total')),
                  ],
                  onChanged: (total) {
                    if (total != null) {
                      notifier.setGearChoices(gear.withSilverRoll(total));
                    }
                  },
                ),
              ],
            ),
            if (rolled)
              Text(
                l10n.moneyLeft(moneyText(l10n, gear.leftCopper(rules))),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            if (gear.bought.isNotEmpty) _Cart(gear: gear, rules: rules),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rolled
              ? CatalogBrowser(
                  rules: rules,
                  canAdd: (entry) => gear.canAfford(rules, entry.id),
                  onAdd: (entry) => _buy(context, ref, entry.id),
                )
              : Center(child: Text(l10n.rollSilverFirst)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: rolled
                    ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const HealthManaPage(),
                        ))
                    : null,
                child: Text(l10n.next),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  int _roll3d6() {
    final random = Random();
    return 3 + random.nextInt(6) + random.nextInt(6) + random.nextInt(6);
  }
}

/// What has been bought so far (closed by default to leave room for the
/// list): − gives one back, + buys another.
class _Cart extends ConsumerWidget {
  const _Cart({required this.gear, required this.rules});

  final GearChoices gear;
  final RulesData rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(characterDraftProvider.notifier);
    final ids = gear.bought.toSet().toList();

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(l10n.boughtTitle(gear.bought.length)),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(shrinkWrap: true, children: [
            for (final id in ids)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${rules.catalogEntry(id).name} ×${gear.count(id)}'),
                subtitle: Text(moneyText(l10n, rules.catalogEntry(id).costCp)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: l10n.refund,
                    onPressed: () => notifier.setGearChoices(gear.refund(id)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: l10n.addItem,
                    onPressed: () => notifier.setGearChoices(gear.buy(id)),
                  ),
                ]),
              ),
          ]),
        ),
      ],
    );
  }
}
