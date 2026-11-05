import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/form_widgets.dart';
import '../sheet/sheet_filter.dart';
import 'lore_entry_page.dart';
import 'lore_providers.dart';
import 'new_tag_dialog.dart';
import 'lore_widgets.dart';

/// One line of the list: a section heading or an entry.
sealed class _Line {}

class _Heading extends _Line {
  _Heading(this.text);
  final String text;
}

class _EntryLine extends _Line {
  _EntryLine(this.item);
  final LoreItem item;
}

/// The Codex: every lore entry (book and own), with search, tag chips and
/// entries grouped by section. Tapping an entry, or a link inside one, opens
/// it; the app bar's back / forward buttons walk the history like a browser.
/// Wide screens: list left, open entry right.
class CodexView extends ConsumerStatefulWidget {
  const CodexView({super.key, required this.lore});

  final LoreContext lore;

  @override
  ConsumerState<CodexView> createState() => _CodexViewState();
}

class _CodexViewState extends ConsumerState<CodexView> {
  static const _wideWidth = 900.0; // list left, open entry right

  final _search = TextEditingController();
  String _query = '';
  final _tags = <String>{}; // chips turned on; none = every tag

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The entries that match, with a heading before each section.
  List<_Line> _lines(AppLocalizations l10n) {
    final filter = SheetFilter(_query);
    final lines = <_Line>[];
    String? lastSection;

    for (final item in widget.lore.items) {
      if (_tags.isNotEmpty && !item.tags.any(_tags.contains)) continue;
      if (!filter.matches([item.name, item.text, item.section, item.note])) {
        continue;
      }
      if (item.section != lastSection) {
        lines.add(_Heading(item.section.isEmpty ? l10n.loreMyEntries : item.section));
        lastSection = item.section;
      }
      lines.add(_EntryLine(item));
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lore = widget.lore;
    final currentId = ref.watch(loreHistoryProvider).current;
    final open = (String? id) =>
        ref.read(loreHistoryProvider.notifier).update((h) => h.open(id));
    final current = currentId == null ? null : lore.byId[currentId];

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _wideWidth;

      final list = _list(l10n, currentId, open);
      final entryPane = current == null
          ? Center(child: Text(l10n.selectEntry))
          : LoreEntryPage(
              key: ValueKey(current.id), // a new page starts at the top
              lore: lore,
              item: current);

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

  Widget _list(AppLocalizations l10n, String? currentId, void Function(String?) open) {
    final lore = widget.lore;
    final lines = _lines(l10n);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search, // keeps the text when the header scrolls away
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: l10n.searchLore,
          ),
          onChanged: (text) => setState(() => _query = text),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final tag in lore.tags)
            FilterChip(
              avatar: TagDot(lore.colorOf(tag.id)),
              label: Text(tag.name),
              selected: _tags.contains(tag.id),
              onSelected: (on) =>
                  setState(() => on ? _tags.add(tag.id) : _tags.remove(tag.id)),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l10n.loreNewTag),
            onPressed: () => addTagWithDialog(context, ref),
          ),
        ]),
      ],
    );

    Widget lineWidget(_Line line) => switch (line) {
          _Heading(:final text) =>
            Padding(padding: const EdgeInsets.only(top: 8), child: SectionTitle(text)),
          _EntryLine(:final item) => ListTile(
              title: Text(item.name),
              selected: item.id == currentId,
              onTap: () => open(item.id),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (lore.pinned.contains(item.id))
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.hub_outlined, size: 16),
                  ),
                for (final tag in item.tags)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: TagDot(lore.colorOf(tag), size: 10),
                  ),
              ]),
            ),
        };

    // ListView.builder: the full list has about 250 rows. Item 0 is the
    // search header; with no match item 1 is the "nothing found" text.
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
