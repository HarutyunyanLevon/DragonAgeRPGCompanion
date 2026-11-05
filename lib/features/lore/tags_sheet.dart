import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/lore.dart';
import '../../shared/confirm_dialog.dart';
import 'color_dialog.dart';
import 'lore_providers.dart';
import 'lore_widgets.dart';

/// Bottom sheet to manage tags: tap a color dot to change it (book tags too),
/// delete the player's own tags, add a new tag.
Future<void> showTagsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TagsSheet(),
    );

class _TagsSheet extends ConsumerStatefulWidget {
  const _TagsSheet();

  @override
  ConsumerState<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends ConsumerState<_TagsSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _changeColor(LoreContext lore, LoreTag tag) async {
    final color = await pickLoreColor(context, ref,
        current: lore.tagColors[tag.id]);
    if (color == null) return;
    // The picker may have added a palette color: read the data again.
    final data = ref.read(loreProvider)!.data;
    await saveLore(ref, setTagColor(data, tag.id, color));
  }

  Future<void> _delete(LoreContext lore, LoreTag tag) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context,
        title: l10n.loreDeleteTitle(tag.name), confirmLabel: l10n.delete);
    if (ok) await saveLore(ref, removeTag(lore.data, tag.id));
  }

  Future<void> _addTag(LoreContext lore) async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final (data, _) = createTag(lore.data, lore.tags, name);
    await saveLore(ref, data);
    _name.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lore = ref.watch(loreProvider);
    if (lore == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final tag in lore.tags)
                ListTile(
                  leading: InkResponse(
                    onTap: () => _changeColor(lore, tag),
                    child: TagDot(lore.colorOf(tag.id), size: 28),
                  ),
                  title: Text(tag.name),
                  onTap: () => _changeColor(lore, tag),
                  trailing: lore.isBookTag(tag.id)
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.delete,
                          onPressed: () => _delete(lore, tag),
                        ),
                ),
            ]),
          ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.loreNewTag),
                onSubmitted: (_) => _addTag(lore),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.loreNewTag,
              onPressed: () => _addTag(lore),
            ),
          ]),
        ]),
      ),
    );
  }
}
