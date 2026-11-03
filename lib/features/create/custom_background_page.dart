import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../rules/models/focus_entry.dart';
import '../../rules/rules_data.dart';
import '../../rules/slug.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';

/// Same shape as a book background (strictly enforced): one ability bonus,
/// two focus choices, 1-2 languages, at least one class. The 2d6 table is
/// copied from a book background. Pops the finished [Background].
class CustomBackgroundPage extends ConsumerStatefulWidget {
  const CustomBackgroundPage({super.key});

  @override
  ConsumerState<CustomBackgroundPage> createState() =>
      _CustomBackgroundPageState();
}

class _CustomBackgroundPageState extends ConsumerState<CustomBackgroundPage> {
  static const _maxLanguages = 2;

  final _name = TextEditingController();
  String? _race;
  String? _ability;
  FocusEntry? _focus1;
  FocusEntry? _focus2;
  final _languages = <String>{};
  final _classes = <String>{};
  Background? _tableSource;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _focusesClash => _focus1 != null && _focus1 == _focus2;

  bool get _isValid =>
      _name.text.trim().isNotEmpty &&
      _race != null &&
      _ability != null &&
      _focus1 != null &&
      _focus2 != null &&
      !_focusesClash &&
      _languages.isNotEmpty &&
      _classes.isNotEmpty &&
      _tableSource != null;

  void _toggle(Set<String> chosen, String id, bool on) {
    setState(() {
      if (on) {
        chosen.add(id);
      } else {
        chosen.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final book = rules.backgrounds.backgrounds;
    final allLanguages = {
      for (final b in book) ...[...b.languages, ...?b.languageChoice?.from],
    }.toList()
      ..sort();
    final focusEntries = [
      for (final f in rules.focuses)
        DropdownMenuEntry(
          value: f,
          label: '${displayName(f.ability)}: ${f.name}',
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customBackground)),
      body: FormBody(children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: l10n.backgroundName),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _Picker<String>(
          label: l10n.race,
          entries: [
            for (final r in playableRaces)
              DropdownMenuEntry(value: r, label: displayName(r)),
          ],
          onSelected: (v) => setState(() => _race = v),
        ),
        _Picker<String>(
          label: l10n.abilityBonus,
          entries: [
            for (final a in rules.backgrounds.abilities)
              DropdownMenuEntry(value: a, label: displayName(a)),
          ],
          onSelected: (v) => setState(() => _ability = v),
        ),
        _Picker<FocusEntry>(
          label: l10n.focusChoice(1),
          entries: focusEntries,
          onSelected: (v) => setState(() => _focus1 = v),
        ),
        _Picker<FocusEntry>(
          label: l10n.focusChoice(2),
          entries: focusEntries,
          errorText: _focusesClash ? l10n.focusChoicesDiffer : null,
          onSelected: (v) => setState(() => _focus2 = v),
        ),
        SectionTitle(l10n.languagesPick),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final language in allLanguages)
            FilterChip(
              label: Text(displayName(language)),
              selected: _languages.contains(language),
              // Disabled once the limit is reached (unless it is already chosen).
              onSelected: _languages.contains(language) ||
                      _languages.length < _maxLanguages
                  ? (on) => _toggle(_languages, language, on)
                  : null,
            ),
        ]),
        const SizedBox(height: 16),
        SectionTitle(l10n.classes),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final c in rules.classes.classes)
            FilterChip(
              label: Text(c.name),
              selected: _classes.contains(c.id),
              onSelected: (on) => _toggle(_classes, c.id, on),
            ),
        ]),
        const SizedBox(height: 16),
        _Picker<Background>(
          label: l10n.copyTableFrom,
          entries: [
            for (final b in book) DropdownMenuEntry(value: b, label: b.name),
          ],
          onSelected: (v) => setState(() => _tableSource = v),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              _isValid ? () => Navigator.of(context).pop(_build(rules)) : null,
          child: Text(l10n.save),
        ),
      ]),
    );
  }

  Background _build(RulesData rules) {
    final book = rules.backgrounds.backgrounds;
    final table = _tableSource!.tables;
    final name = _name.text.trim();
    return Background(
      id: 'custom-${slug(name)}',
      name: name,
      races: [_race!],
      abilityBonus: _ability!,
      focusChoices: [
        for (final f in [_focus1!, _focus2!])
          FocusRef(ability: f.ability, focus: f.id),
      ],
      languages: _languages.toList(),
      classes: [
        // In the book's class order.
        for (final c in rules.classes.classes)
          if (_classes.contains(c.id)) c.id,
      ],
      // Same racial trait as the book backgrounds of this race.
      trait: book
          .where((b) => b.races.contains(_race))
          .map((b) => b.trait)
          .firstWhere((t) => t != null, orElse: () => null),
      casteChoices: const [],
      // A table written for one race still works: use the one that fits.
      tables: {'any': table['any'] ?? table[_race] ?? table.values.first},
      notes: const [],
      homebrew: true,
    );
  }
}

/// A dropdown with type-to-filter, full width.
class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.entries,
    required this.onSelected,
    this.errorText,
  });

  final String label;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownMenu<T>(
        label: Text(label),
        errorText: errorText,
        expandedInsets: EdgeInsets.zero,
        enableFilter: true,
        dropdownMenuEntries: entries,
        onSelected: onSelected,
      ),
    );
  }
}
