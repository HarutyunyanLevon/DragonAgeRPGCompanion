import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../rules/models/focus_entry.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import 'benefit_results.dart';

/// The roll ranges (min, max) of every 2d6 background table in the book.
const tableRanges = [
  (2, 2),
  (3, 4),
  (5, 5),
  (6, 6),
  (7, 8),
  (9, 9),
  (10, 11),
  (12, 12),
];

/// Everything a table row can be set to. The lists come from the rules data.
class RowChoices {
  const RowChoices({
    required this.abilities,
    required this.focuses,
    required this.languages,
    required this.weaponGroups,
  });

  final List<String> abilities;
  final List<FocusEntry> focuses;
  final List<String> languages;
  final List<String> weaponGroups;
}

/// The 8 rows of a custom background's 2d6 table. A row is [TableResult]
/// or null while it is not set. Tapping a row opens a sheet to set it.
class TableRowEditor extends StatelessWidget {
  const TableRowEditor({
    super.key,
    required this.results,
    required this.choices,
    required this.onChanged,
  });

  /// One entry per [tableRanges] entry.
  final List<TableResult?> results;
  final RowChoices choices;
  final void Function(int row, TableResult result) onChanged;

  static String _range(int row) =>
      rangeText(tableRanges[row].$1, tableRanges[row].$2);

  /// The range of an earlier row that gives the same, or null.
  String? _duplicateOf(int row) {
    final result = results[row];
    if (result == null) return null;
    for (var earlier = 0; earlier < row; earlier++) {
      if (results[earlier]?.sameAs(result) ?? false) return _range(earlier);
    }
    return null;
  }

  Future<void> _edit(BuildContext context, int row) async {
    final result = await showModalBottomSheet<TableResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RowSheet(
        title: AppLocalizations.of(context).rowTitle(_range(row)),
        choices: choices,
        current: results[row],
      ),
    );
    if (result != null) onChanged(row, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l10n.tableRowsTitle),
      Text(l10n.tableRowsHelp),
      const SizedBox(height: 8),
      for (var row = 0; row < results.length; row++)
        Card(
          child: ListTile(
            leading: Text(_range(row),
                style: Theme.of(context).textTheme.titleMedium),
            title: Text(results[row] == null
                ? l10n.notSet
                : resultText(l10n, results[row]!)),
            subtitle: _duplicateOf(row) == null
                ? null
                : Text(l10n.sameAsRow(_duplicateOf(row)!)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _edit(context, row),
          ),
        ),
    ]);
  }
}

/// Bottom sheet for one row: pick what it gives. Pops the new [TableResult].
class _RowSheet extends StatefulWidget {
  const _RowSheet({
    required this.title,
    required this.choices,
    required this.current,
  });

  final String title;
  final RowChoices choices;
  final TableResult? current;

  @override
  State<_RowSheet> createState() => _RowSheetState();
}

class _RowSheetState extends State<_RowSheet> {
  static const _types = ['ability', 'focus', 'language', 'weaponGroup'];

  late String _type = widget.current?.type ?? _types.first;
  String _query = '';

  RowChoices get _choices => widget.choices;

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
        'ability' => l10n.typeAbility,
        'focus' => l10n.typeFocus,
        'language' => l10n.typeLanguage,
        _ => l10n.typeWeaponGroup,
      };

  /// Picking what the row already gives keeps the row as it was (so a
  /// book row keeps its "if the class has it" fallback).
  void _done(TableResult result) {
    final current = widget.current;
    final keepCurrent = current != null && current.sameAs(result);
    Navigator.pop(context, keepCurrent ? current : result);
  }

  bool _isCurrent(TableResult result) =>
      widget.current?.sameAs(result) ?? false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(widget.title),
              Wrap(spacing: 8, children: [
                for (final type in _types)
                  ChoiceChip(
                    label: Text(_typeLabel(l10n, type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ]),
              const SizedBox(height: 12),
              Expanded(child: _options(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _options(AppLocalizations l10n) => switch (_type) {
        'ability' => _chips([
            for (final a in _choices.abilities)
              (displayName(a), TableResult(type: 'ability', ability: a)),
          ]),
        'language' => _chips([
            for (final l in _choices.languages)
              (displayName(l), TableResult(type: 'language', language: l)),
          ]),
        'weaponGroup' => _chips([
            for (final g in _choices.weaponGroups)
              (displayName(g), TableResult(type: 'weaponGroup', group: g)),
          ]),
        _ => _focusList(l10n),
      };

  /// One chip per option; tapping a chip sets the row and closes the sheet.
  Widget _chips(List<(String, TableResult)> options) => SingleChildScrollView(
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          for (final (label, result) in options)
            ChoiceChip(
              label: Text(label),
              selected: _isCurrent(result),
              onSelected: (_) => _done(result),
            ),
        ]),
      );

  /// The ~80 focuses are too many for chips: a searchable list instead.
  Widget _focusList(AppLocalizations l10n) {
    final query = _query.toLowerCase();
    final matches = [
      for (final f in _choices.focuses)
        if ('${displayName(f.ability)} ${f.name}'.toLowerCase().contains(query))
          f,
    ];

    return Column(children: [
      TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.searchFocuses,
        ),
        onChanged: (text) => setState(() => _query = text),
      ),
      Expanded(
        child: ListView(children: [
          for (final f in matches)
            ListTile(
              title: Text(f.name),
              subtitle: Text(displayName(f.ability)),
              selected: _isCurrent(
                  TableResult(type: 'focus', ability: f.ability, focus: f.id)),
              onTap: () => _done(
                  TableResult(type: 'focus', ability: f.ability, focus: f.id)),
            ),
        ]),
      ),
    ]);
  }
}
