import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/lore.dart';
import '../../l10n/app_localizations.dart';
import '../characters/character_button.dart';
import '../characters/character_view.dart';
import '../play/play_info_card.dart';
import 'codex_view.dart';
import 'lore_entry_dialog.dart';
import 'lore_files.dart';
import 'lore_graph_view.dart';
import 'lore_providers.dart';
import 'new_tag_dialog.dart';
import 'tags_sheet.dart';

/// Lore tab. Two views of the same lore, switched at the top: the Codex (a
/// list of entries to read) and the Graph (the entries the player pinned,
/// with strings). Lore belongs to the selected character.
class LorePage extends ConsumerWidget {
  const LorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(loreModeProvider);
    final history = ref.watch(loreHistoryProvider);
    final nav = ref.read(loreHistoryProvider.notifier);
    final editing = ref.watch(loreEditingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabLore),
        actions: [
          // Back / forward / list belong to the Codex only.
          if (mode == LoreMode.codex) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.glossaryBack,
              onPressed: history.canGoBack
                  ? () => nav.update((h) => h.back())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: l10n.glossaryForward,
              onPressed: history.canGoForward
                  ? () => nav.update((h) => h.forward())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: l10n.glossaryList,
              onPressed: history.current == null
                  ? null
                  : () => nav.update((h) => h.open(null)),
            ),
          ],
          // Editing and organizing belong to the Graph only.
          if (mode == LoreMode.graph) ...[
            IconButton(
              icon: Icon(editing ? Icons.check : Icons.edit),
              tooltip: l10n.editWidgets,
              onPressed: () => _setEditing(ref, !editing),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_mosaic_outlined),
              tooltip: l10n.loreOrganize,
              onPressed: () => _organize(ref),
            ),
          ],
          const CharacterButton(),
        ],
      ),
      body: CharacterView(
          builder: (character, rules) => _LoreBody(character: character)),
    );
  }
}

/// Edit mode of the tiles on, or off. A card left open by a tile is closed.
void _setEditing(WidgetRef ref, bool editing) {
  ref.read(playInfoProvider.notifier).state = null;
  ref.read(loreEditingProvider.notifier).state = editing;
}

/// Puts all tiles of the graph in tidy rows.
Future<void> _organize(WidgetRef ref) async {
  final lore = ref.read(loreProvider);
  if (lore == null) return;
  await saveLore(ref, organizeNodes(lore.data, lore.byId));
}

enum _MenuAction { newTag, tags, export, import }

class _LoreBody extends ConsumerWidget {
  const _LoreBody({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lore = ref.watch(loreProvider);
    final mode = ref.watch(loreModeProvider);
    if (lore == null) return const SizedBox.shrink();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
        child: Row(children: [
          SegmentedButton<LoreMode>(
            segments: [
              ButtonSegment(
                value: LoreMode.codex,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.loreCodex),
              ),
              ButtonSegment(
                value: LoreMode.graph,
                icon: const Icon(Icons.hub_outlined),
                label: Text(l10n.loreGraph),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selected) =>
                ref.read(loreModeProvider.notifier).state = selected.first,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.newLoreEntry,
            // In Graph mode the new entry is also pinned on the graph.
            onPressed: () =>
                showLoreEntryDialog(context, ref, pin: mode == LoreMode.graph),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => switch (action) {
              _MenuAction.newTag => addTagWithDialog(context, ref),
              _MenuAction.tags => showTagsSheet(context),
              _MenuAction.export => exportLore(context, ref),
              _MenuAction.import => importLore(context, ref),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: _MenuAction.newTag, child: Text(l10n.loreNewTag)),
              PopupMenuItem(value: _MenuAction.tags, child: Text(l10n.loreManageTags)),
              PopupMenuItem(value: _MenuAction.export, child: Text(l10n.loreExport)),
              PopupMenuItem(value: _MenuAction.import, child: Text(l10n.loreImport)),
            ],
          ),
        ]),
      ),
      // Both views stay alive, so the Codex keeps its search and the graph
      // keeps its zoom when the player switches.
      Expanded(
        child: IndexedStack(
          sizing: StackFit.expand,
          index: mode.index,
          children: [
            CodexView(lore: lore),
            LoreGraphView(lore: lore, character: character),
          ],
        ),
      ),
    ]);
  }
}
