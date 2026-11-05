import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/form_widgets.dart';
import '../../shared/linked_text.dart';
import 'lore_entry_dialog.dart';
import 'lore_providers.dart';
import 'lore_widgets.dart';

/// One open Codex entry: name, tags, text, the "See also" chips and the
/// buttons (graph, edit, delete). Names inside the text and the chips both
/// open other entries (and add them to the history).
class LoreEntryPage extends ConsumerWidget {
  const LoreEntryPage({super.key, required this.lore, required this.item});

  final LoreContext lore;
  final LoreItem item;

  void _open(WidgetRef ref, String id) =>
      ref.read(loreHistoryProvider.notifier).update((h) => h.open(id));

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context,
        title: l10n.loreDeleteTitle(item.name), confirmLabel: l10n.delete);
    if (!ok) return;
    await saveLore(ref, removeMyEntry(lore.data, item.id));
    ref.read(loreHistoryProvider.notifier).update((h) => h.open(null));
  }

  Future<void> _addToGraph(BuildContext context, WidgetRef ref) async {
    final message = AppLocalizations.of(context).loreAddedToGraph;
    final messenger = ScaffoldMessenger.of(context);
    await saveLore(ref, pinEntry(lore.data, item.id, lore.byId));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onGraph = lore.pinned.contains(item.id);
    final seeAlso = [for (final id in item.links) if (lore.byId.containsKey(id)) id];

    return TextLinks(
      find: (text) => lore.linker.find(text, selfKey: item.id),
      onOpen: (id) => _open(ref, id),
      child: FormBody(
        maxWidth: 640,
        children: [
          Text(item.name, style: theme.textTheme.headlineSmall),
          if (item.section.isNotEmpty)
            Text(item.section, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          TagChips(lore: lore, tagIds: item.tags),
          const SizedBox(height: 12),
          LinkedText(item.text),
          if (seeAlso.isNotEmpty) ...[
            SubsectionTitle(l10n.loreSeeAlso),
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final id in seeAlso)
                ActionChip(
                  avatar: TagDot(lore.colorOf(lore.byId[id]!.tags.firstOrNull ?? '')),
                  label: Text(lore.byId[id]!.name),
                  onPressed: () => _open(ref, id),
                ),
            ]),
          ],
          if (item.note.isNotEmpty) ...[
            SubsectionTitle(l10n.loreNote),
            Text(item.note),
          ],
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (onGraph)
              OutlinedButton.icon(
                icon: const Icon(Icons.hub_outlined),
                label: Text(l10n.loreRemoveFromGraph),
                onPressed: () =>
                    saveLore(ref, unpinEntry(lore.data, item.id)),
              )
            else
              FilledButton.tonalIcon(
                icon: const Icon(Icons.hub_outlined),
                label: Text(l10n.loreAddToGraph),
                onPressed: () => _addToGraph(context, ref),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.editItem),
              onPressed: () => showLoreEntryDialog(context, ref, item: item),
            ),
            if (item.isMine)
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.delete),
                onPressed: () => _delete(context, ref),
              ),
          ]),
        ],
      ),
    );
  }
}
