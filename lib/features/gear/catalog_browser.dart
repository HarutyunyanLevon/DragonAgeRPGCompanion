import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/gear.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/info_row.dart';
import '../../shared/money.dart';
import '../create/rule_info.dart';

/// Search box, category chips and every item of gear.json as an expandable
/// row (the description is the item's facts and price). The "+" button of a
/// row calls [onAdd]. Used by the wizard's shop and the Sheet's "Add item".
///
/// [canAdd] only dims the button (e.g. too expensive); [onAdd] decides what
/// to do. [footer] is shown under the list.
class CatalogBrowser extends StatefulWidget {
  const CatalogBrowser({
    super.key,
    required this.rules,
    required this.onAdd,
    this.canAdd,
    this.footer,
  });

  final RulesData rules;
  final ValueChanged<CatalogEntry> onAdd;
  final bool Function(CatalogEntry entry)? canAdd;
  final Widget? footer;

  @override
  State<CatalogBrowser> createState() => _CatalogBrowserState();
}

class _CatalogBrowserState extends State<CatalogBrowser> {
  String _query = '';
  String? _category; // null: all categories
  final _chipScroll = ScrollController();

  @override
  void dispose() {
    _chipScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = widget.rules.catalog;
    final categories = {for (final e in catalog) e.category}.toList();
    final matches = [
      for (final e in catalog)
        if ((_category == null || e.category == _category) &&
            e.name.toLowerCase().contains(_query.toLowerCase()))
          e,
    ];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: InputDecoration(
            labelText: l10n.searchItems,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (text) => setState(() => _query = text),
        ),
      ),
      // A mouse cannot drag a scroll view by default, so allow it here and
      // show a scrollbar (the chips are wider than a phone screen).
      ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: Scrollbar(
          controller: _chipScroll,
          child: SingleChildScrollView(
            controller: _chipScroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(displayName(category)),
                    selected: _category == category,
                    onSelected: (selected) => setState(
                        () => _category = selected ? category : null),
                  ),
                ),
            ]),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: matches.length,
          itemBuilder: (_, index) {
            final entry = matches[index];
            final affordable = widget.canAdd?.call(entry) ?? true;
            return InfoRow(
              leading: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l10n.addItem,
                color: affordable ? null : Theme.of(context).disabledColor,
                onPressed: () => widget.onAdd(entry),
              ),
              title: entry.name,
              subtitle: displayName(entry.category),
              value: moneyText(l10n, entry.costCp),
              child: ItemInfo(
                  rules: widget.rules, itemId: entry.id, name: entry.name),
            );
          },
        ),
      ),
      if (widget.footer != null) widget.footer!,
    ]);
  }
}
