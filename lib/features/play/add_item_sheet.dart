import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/play_items.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../spells/custom_spells.dart';
import 'free_item_dialog.dart';

/// A sheet with a search field and everything that can be added to a widget:
/// things the character has, then free items. Returns the chosen item, or
/// null when closed.
Future<PlayItem?> pickItem(
    BuildContext context, WidgetRef ref, Character character, RulesData rules) {
  final options = itemOptions(character, rules, ref.read(allSpellsProvider));

  return showModalBottomSheet<PlayItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickItemSheet(options: options),
  );
}

/// Asks which free item to add (text, checkbox, ...) and its fields. Returns
/// the item, or null when cancelled. For places that take only free items.
Future<PlayItem?> pickFreeItem(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final type = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10n.itemGroupFree),
      children: [
        for (final type in freeItemTypes)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, type),
            child: Text(freeItemName(l10n, type)),
          ),
      ],
    ),
  );
  if (type == null || !context.mounted) return null;
  return editFreeItem(context, type: type);
}

String _groupName(AppLocalizations l10n, ItemGroup group) => switch (group) {
      ItemGroup.abilities => l10n.abilities,
      ItemGroup.focuses => l10n.focuses,
      ItemGroup.weapons => l10n.weapons,
      ItemGroup.spells => l10n.spells,
      ItemGroup.stats => l10n.itemGroupStats,
      ItemGroup.talents => l10n.talents,
      ItemGroup.specializations => l10n.specializations,
      ItemGroup.languages => l10n.languages,
      ItemGroup.traits => l10n.itemGroupTraits,
      ItemGroup.gear => l10n.itemGroupGear,
    };

class _PickItemSheet extends StatefulWidget {
  const _PickItemSheet({required this.options});

  final List<ItemOption> options;

  @override
  State<_PickItemSheet> createState() => _PickItemSheetState();
}

class _PickItemSheetState extends State<_PickItemSheet> {
  String _query = '';

  // Which chip is selected: 'free', 'all' or the name of an [ItemGroup].
  // Free items come first, as they need no character data.
  String _section = 'free';

  Future<void> _addFree(String type) async {
    final item = await editFreeItem(context, type: type);
    if (item != null && mounted) Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim().toLowerCase();
    bool matches(String name) => name.toLowerCase().contains(query);

    final showFree = _section == 'free' || _section == 'all';
    final freeTypes = [
      if (showFree)
        for (final type in freeItemTypes)
          if (matches(freeItemName(l10n, type))) type,
    ];
    final groups = [
      for (final group in ItemGroup.values)
        if (widget.options.any((o) => o.group == group)) group,
    ];

    Widget chip(String key, String label) => ChoiceChip(
          label: Text(label),
          selected: _section == key,
          onSelected: (_) => setState(() => _section = key),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchItems,
            ),
            onChanged: (text) => setState(() => _query = text),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 6, runSpacing: 0, children: [
              chip('free', l10n.itemGroupFree),
              for (final group in groups) chip(group.name, _groupName(l10n, group)),
              chip('all', l10n.allItems),
            ]),
          ),
        ),
        Expanded(
          child: ListView(children: [
            if (freeTypes.isNotEmpty) ...[
              if (_section == 'all') _heading(l10n.itemGroupFree),
              for (final type in freeTypes)
                ListTile(
                  title: Text(freeItemName(l10n, type)),
                  onTap: () => _addFree(type),
                ),
            ],
            for (final group in ItemGroup.values)
              if (_section == 'all' || _section == group.name)
                ..._groupRows(l10n, group, matches),
          ]),
        ),
      ]),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  List<Widget> _groupRows(
      AppLocalizations l10n, ItemGroup group, bool Function(String) matches) {
    final shown = [
      for (final o in widget.options)
        if (o.group == group && matches(o.name)) o,
    ];
    if (shown.isEmpty) return [];

    return [
      _heading(_groupName(l10n, group)),
      for (final option in shown)
        ListTile(
          dense: true,
          title: Text(option.name),
          onTap: () => Navigator.pop(context, option.item),
        ),
    ];
  }
}
