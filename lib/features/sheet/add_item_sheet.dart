import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../gear/catalog_browser.dart';

/// Opens the "Add item" sheet. Returns the picked item, or null if closed.
Future<InventoryItem?> showAddItemSheet(BuildContext context, RulesData rules) {
  return showModalBottomSheet<InventoryItem>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _AddItemSheet(rules: rules),
  );
}

/// The catalog; tapping "+" adds the item and closes the sheet. At the bottom
/// a field adds a custom item.
class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.rules});

  final RulesData rules;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _customName = TextEditingController();

  @override
  void dispose() {
    _customName.dispose();
    super.dispose();
  }

  void _addCustom() {
    final name = _customName.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, InventoryItem(name: name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        // Keeps the fields above the on-screen keyboard.
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: CatalogBrowser(
            rules: widget.rules,
            onAdd: (entry) => Navigator.pop(
                context, InventoryItem(name: entry.name, itemId: entry.id)),
            footer: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _customName,
                    decoration: InputDecoration(labelText: l10n.customItemName),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addCustom(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: l10n.addCustomItem,
                  onPressed: _addCustom,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
