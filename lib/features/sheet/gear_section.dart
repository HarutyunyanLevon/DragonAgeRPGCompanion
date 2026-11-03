import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/equipment.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import '../../shared/info_row.dart';
import '../../shared/money.dart';
import '../../shared/sheet_box.dart';
import '../create/rule_info.dart';
import 'add_item_sheet.dart';
import 'money_dialog.dart';
import 'sheet_filter.dart';

/// Money, the inventory list and "Add item". Tap an item to read about it
/// and to change its quantity or remove it. Every change saves at once.
class GearSection extends ConsumerWidget {
  const GearSection({
    super.key,
    required this.character,
    required this.rules,
    required this.filter,
  });

  final Character character;
  final RulesData rules;
  final SheetFilter filter;

  /// The money row matches a search for "money" or "silver" and the like.
  static bool _moneyMatches(AppLocalizations l10n, SheetFilter filter) =>
      filter.matches([l10n.money, l10n.silverLabel]);

  /// The inventory indexes that match the search.
  static List<int> _items(
          Character character, RulesData rules, SheetFilter filter) =>
      [
        for (var i = 0; i < character.inventory.length; i++)
          if (filter.matches(itemTexts(rules, character.inventory[i]))) i
      ];

  static bool hasMatches(AppLocalizations l10n, Character character,
          RulesData rules, SheetFilter filter) =>
      _moneyMatches(l10n, filter) ||
      _items(character, rules, filter).isNotEmpty;

  Future<void> _save(WidgetRef ref, Character changed) =>
      ref.read(charactersProvider.notifier).save(changed);

  Future<void> _setInventory(WidgetRef ref, List<InventoryItem> inventory) =>
      _save(ref, character.copyWith(inventory: inventory));

  Future<void> _editMoney(BuildContext context, WidgetRef ref) async {
    final copper = await showMoneyDialog(context, character.copper);
    if (copper != null) await _save(ref, character.copyWith(copper: copper));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final item = await showAddItemSheet(context, rules);
    if (item != null) {
      await _setInventory(ref, addItem(character.inventory, item));
    }
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, int index) async {
    final l10n = AppLocalizations.of(context);
    final item = character.inventory[index];
    final confirmed = await confirm(
      context,
      title: l10n.removeItemTitle(item.name),
      confirmLabel: l10n.remove,
    );
    if (confirmed) {
      await _setInventory(ref, [
        for (var i = 0; i < character.inventory.length; i++)
          if (i != index) character.inventory[i],
      ]);
    }
  }

  Future<void> _changeQuantity(WidgetRef ref, int index, int change) {
    final item = character.inventory[index];
    return _setInventory(ref, [
      for (var i = 0; i < character.inventory.length; i++)
        i == index
            ? item.copyWith(quantity: item.quantity + change)
            : character.inventory[i],
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inventory = character.inventory;
    final shown = _items(character, rules, filter);
    final showMoney = _moneyMatches(l10n, filter);
    if (!hasMatches(l10n, character, rules, filter)) {
      return const SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l10n.sectionGear),
      SheetBox(children: [
        if (showMoney)
          InfoRow(
            leading: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editMoney,
              onPressed: () => _editMoney(context, ref),
            ),
            title: moneyText(l10n, character.copper),
            child: const MoneyInfo(),
          ),
        if (inventory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.inventoryEmpty, textAlign: TextAlign.center),
          ),
        for (final i in shown)
          InfoRow(
            leading: canEquip(rules, inventory[i])
                ? Checkbox(
                    value: inventory[i].equipped,
                    onChanged: (_) => _setInventory(
                        ref, toggleEquipped(inventory, i, rules)),
                  )
                : null,
            title: inventory[i].name,
            subtitle: _details(l10n, inventory[i]),
            value:
                inventory[i].quantity > 1 ? '×${inventory[i].quantity}' : null,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ItemInfo(
                rules: rules,
                itemId: inventory[i].itemId,
                name: inventory[i].name,
                note: inventory[i].note,
              ),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: inventory[i].quantity > 1
                      ? () => _changeQuantity(ref, i, -1)
                      : null,
                ),
                Text('${inventory[i].quantity}'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _changeQuantity(ref, i, 1),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.remove),
                  onPressed: () => _remove(context, ref, i),
                ),
              ]),
            ]),
          ),
      ]),
      if (!filter.isActive)
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addItem),
          onPressed: () => _add(context, ref),
        ),
    ]);
  }

  /// The line under an item's name: armor, shield or weapon numbers.
  String? _details(AppLocalizations l10n, InventoryItem item) {
    final armor = rules.armorById(item.itemId);
    if (armor != null) {
      return l10n.armorLine(armor.armorRating, armor.armorPenalty);
    }
    final shield = rules.shieldById(item.itemId);
    if (shield != null) return l10n.shieldLine(signed(shield.defenseBonus));

    final weapon = rules.weaponById(item.itemId);
    if (weapon == null) return null;
    if (!item.equipped) {
      return l10n.weaponLine(weapon.damage, displayName(weapon.group));
    }
    final numbers = weaponNumbers(character, weapon, rules);
    final line = l10n.weaponNumbersLine(signed(numbers.attack), numbers.damage);
    return numbers.trained ? line : '$line. ${l10n.untrainedWeapon}';
  }
}
