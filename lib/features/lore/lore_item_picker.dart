import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../sheet/sheet_filter.dart';
import 'lore_providers.dart';

/// Asks the player to pick one entry (search + list). Entries in [exclude]
/// are not offered. Returns the entry id, or null when cancelled.
Future<String?> pickLoreItem(
  BuildContext context,
  LoreContext lore, {
  Set<String> exclude = const {},
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ItemPicker(lore: lore, exclude: exclude),
  );
}

class _ItemPicker extends StatefulWidget {
  const _ItemPicker({required this.lore, required this.exclude});

  final LoreContext lore;
  final Set<String> exclude;

  @override
  State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
  static const _maxRows = 50; // typing narrows the list down

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = SheetFilter(_query);
    final matches = [
      for (final item in widget.lore.items)
        if (!widget.exclude.contains(item.id) && filter.matches([item.name]))
          item,
    ];

    return AlertDialog(
      title: Text(l10n.loreAddLink),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.searchLore,
            ),
            onChanged: (text) => setState(() => _query = text),
          ),
          Expanded(
            child: ListView(children: [
              for (final item in matches.take(_maxRows))
                ListTile(
                  title: Text(item.name),
                  subtitle: item.section.isEmpty ? null : Text(item.section),
                  onTap: () => Navigator.pop(context, item.id),
                ),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
