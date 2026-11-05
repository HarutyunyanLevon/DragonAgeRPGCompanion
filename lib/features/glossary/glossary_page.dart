import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/form_widgets.dart';
import '../../shared/linked_text.dart';
import '../sheet/sheet_filter.dart';
import 'glossary_entries.dart';
import 'glossary_entry_view.dart';
import 'glossary_providers.dart';
import 'note_dialog.dart';

/// Glossary tab. The list of entries (search + category chips); tapping an
/// entry, or a link inside one, opens it. Back / forward buttons walk through
/// the entries seen, like a browser. It needs no character.
///
/// Wide screens: list on the left, open entry on the right. Phone: the list
/// or the open entry fills the tab.
class GlossaryPage extends ConsumerWidget {
  const GlossaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider);
    final history = ref.watch(glossaryHistoryProvider);
    final nav = ref.read(glossaryHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabGlossary),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.glossaryBack,
            onPressed: history.canGoBack ? nav.back : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: l10n.glossaryForward,
            onPressed: history.canGoForward ? nav.forward : null,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: l10n.glossaryList,
            onPressed: history.current == null ? null : () => nav.open(null),
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: l10n.newNote,
            onPressed: () => showNoteDialog(context, ref),
          ),
        ],
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.rulesFailed(error.toString()))),
        data: (rulesData) => _GlossaryBody(rules: rulesData),
      ),
    );
  }
}

/// One line of the list: a heading or an entry.
sealed class _Line {}

class _Heading extends _Line {
  _Heading(this.text, {required this.big});
  final String text;
  final bool big; // a category (big) or a group inside it
}

class _EntryLine extends _Line {
  _EntryLine(this.entry);
  final GlossaryEntry entry;
}

class _GlossaryBody extends ConsumerStatefulWidget {
  const _GlossaryBody({required this.rules});

  final RulesData rules;

  @override
  ConsumerState<_GlossaryBody> createState() => _GlossaryBodyState();
}

class _GlossaryBodyState extends ConsumerState<_GlossaryBody> {
  static const _wideWidth = 900.0; // list left, open entry right

  final _search = TextEditingController();
  String _query = '';
  GlossaryCategory? _category; // null: every category

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, GlossaryCategory category) =>
      switch (category) {
        GlossaryCategory.terms => l10n.glossaryTerms,
        GlossaryCategory.stunts => l10n.glossaryStunts,
        GlossaryCategory.classes => l10n.glossaryClasses,
        GlossaryCategory.weaponGroups => l10n.weaponGroups,
        GlossaryCategory.abilities => l10n.glossaryAbilities,
        GlossaryCategory.talents => l10n.talents,
        GlossaryCategory.specializations => l10n.specializations,
        GlossaryCategory.focuses => l10n.focuses,
        GlossaryCategory.gear => l10n.glossaryGear,
        GlossaryCategory.spells => l10n.spells,
        GlossaryCategory.notes => l10n.glossaryNotes,
      };

  /// The entries that match, with a heading before each category and group.
  List<_Line> _lines(AppLocalizations l10n, List<GlossaryEntry> all) {
    final filter = SheetFilter(_query);
    final lines = <_Line>[];
    GlossaryCategory? lastCategory;
    String lastGroup = '';

    for (final entry in all) {
      if (_category != null && entry.category != _category) continue;
      if (!filter.matches(entry.searchTexts)) continue;

      if (entry.category != lastCategory) {
        lines.add(_Heading(_categoryLabel(l10n, entry.category), big: true));
        lastCategory = entry.category;
        lastGroup = '';
      }
      if (entry.group != lastGroup) {
        lines.add(_Heading(entry.group, big: false));
        lastGroup = entry.group;
      }
      lines.add(_EntryLine(entry));
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(glossaryEntriesProvider);
    final currentKey = ref.watch(glossaryHistoryProvider).current;
    final open = ref.read(glossaryHistoryProvider.notifier).open;
    final current = entries.where((e) => e.key == currentKey).firstOrNull;

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _wideWidth;

      // The list is the whole tab on a phone when no entry is open.
      final list = _list(l10n, entries, currentKey, open);
      final entryPane = current == null
          ? Center(child: Text(l10n.selectEntry))
          : _EntryPage(
              key: ValueKey(current.key), // a new page starts at the top
              rules: widget.rules,
              entry: current);

      if (wide) {
        return Row(children: [
          Expanded(flex: 3, child: list),
          const VerticalDivider(width: 1),
          Expanded(flex: 2, child: entryPane),
        ]);
      }
      return current == null ? list : entryPane;
    });
  }

  Widget _list(AppLocalizations l10n, List<GlossaryEntry> entries,
      String? currentKey, void Function(String?) open) {
    final lines = _lines(l10n, entries);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search, // keeps the text when the header scrolls away
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: l10n.searchGlossary,
          ),
          onChanged: (text) => setState(() => _query = text),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final category in GlossaryCategory.values)
            FilterChip(
              label: Text(_categoryLabel(l10n, category)),
              selected: _category == category,
              onSelected: (on) =>
                  setState(() => _category = on ? category : null),
            ),
        ]),
      ],
    );

    Widget lineWidget(_Line line) => switch (line) {
          _Heading(:final text, :final big) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: big ? SectionTitle(text) : SubsectionTitle(text),
            ),
          _EntryLine(:final entry) => ListTile(
              title: Text(entry.title),
              selected: entry.key == currentKey,
              onTap: () => open(entry.key),
            ),
        };

    // ListView.builder: the full list has several hundred rows. Item 0 is
    // the search header; with no match item 1 is the "nothing found" text.
    final listView = ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.isEmpty ? 2 : lines.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return header;
        if (lines.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.noGlossaryMatches, textAlign: TextAlign.center),
          );
        }
        return lineWidget(lines[i - 1]);
      },
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: listView,
      ),
    );
  }
}

/// One open entry: its title and description. Words that name another entry
/// are links; tapping one opens that entry (and adds it to the history).
class _EntryPage extends ConsumerWidget {
  const _EntryPage({super.key, required this.rules, required this.entry});

  final RulesData rules;
  final GlossaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linker = ref.watch(glossaryLinkerProvider);
    final open = ref.read(glossaryHistoryProvider.notifier).open;
    final theme = Theme.of(context);

    return TextLinks(
      find: (text) => linker.find(text, selfKey: entry.key),
      onOpen: open,
      child: FormBody(
        maxWidth: 640,
        children: [
          Text(entry.title, style: theme.textTheme.headlineSmall),
          if (entry.group.isNotEmpty)
            Text(entry.group, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          GlossaryEntryView(rules: rules, entry: entry),
        ],
      ),
    );
  }
}
