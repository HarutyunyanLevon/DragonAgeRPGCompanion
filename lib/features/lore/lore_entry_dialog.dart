import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../character/lore_data.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/lore.dart';
import 'lore_item_picker.dart';
import 'lore_providers.dart';
import 'new_tag_dialog.dart';
import 'lore_widgets.dart';

/// The entry form. Without [item] it makes a new entry of the player's own.
/// With an own [item] it edits it; with a book [item] it edits only what the
/// player can add to it (tags, links, a note): the book text stays read-only.
///
/// With [pin] a new entry is also put on the graph (used in Graph mode).
Future<void> showLoreEntryDialog(BuildContext context, WidgetRef ref,
    {LoreItem? item, bool pin = false}) async {
  final lore = ref.read(loreProvider);
  if (lore == null) return;
  var result = await showDialog<LoreData>(
    context: context,
    builder: (_) => _EntryForm(lore: lore, item: item),
  );
  if (result == null) return;

  if (pin && item == null) {
    final before = {for (final e in lore.data.myEntries) e.id};
    final created = result.myEntries.firstWhere((e) => !before.contains(e.id));
    final items = buildLoreItems(lore.rules.loreEntries, result);
    result = pinEntry(result, created.id, {for (final i in items) i.id: i});
  }
  await saveLore(ref, result);
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.lore, this.item});

  final LoreContext lore;
  final LoreItem? item;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _text = TextEditingController(text: widget.item?.text ?? '');
  late final _note = TextEditingController(text: widget.item?.note ?? '');
  late final List<String> _tags = [...?widget.item?.tags];
  late final List<String> _links = [...?widget.item?.links];

  // The form works on its own copy: a tag made here is kept only if the
  // entry is saved.
  late LoreContext _lore = widget.lore;
  bool get _isBook => widget.item != null && !widget.item!.isMine;

  // What the book itself gives (nothing for an own entry): the player cannot
  // take it away.
  late final LoreEntry? _book =
      _isBook ? _lore.bookEntry(widget.item!.id) : null;
  List<String> get _bookTags => _book?.tags ?? const [];
  List<String> get _bookLinks => _book?.links ?? const [];

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _isBook || _name.text.trim().isNotEmpty;

  void _toggleTag(String id, bool on) =>
      setState(() => on ? _tags.add(id) : _tags.remove(id));

  Future<void> _newTag() async {
    final name = await askTagName(context);
    if (name == null) return;
    final (data, tag) = createTag(_lore.data, _lore.tags, name);
    setState(() {
      _lore = LoreContext(_lore.rules, data);
      _tags.add(tag.id);
    });
  }

  Future<void> _addLink() async {
    final id = await pickLoreItem(context, _lore,
        exclude: {..._links, if (widget.item != null) widget.item!.id});
    if (id != null) setState(() => _links.add(id));
  }

  /// Entries named in what was typed and not linked yet.
  List<String> get _suggestions => _isBook
      ? const []
      : [
          for (final id in suggestLinks(
              '${_name.text} ${_text.text}', widget.item?.id ?? '', _lore.linker))
            if (!_links.contains(id)) id,
        ];

  LoreData _result() {
    final data = _lore.data;
    final item = widget.item;

    if (_isBook) {
      return setAddition(
        data,
        LoreAddition(
          entryId: item!.id,
          tags: [for (final t in _tags) if (!_bookTags.contains(t)) t],
          links: [for (final l in _links) if (!_bookLinks.contains(l)) l],
          note: _note.text.trim(),
        ),
      );
    }

    final name = _name.text.trim();
    final entry = MyLoreEntry(
      id: item?.id ?? newLoreId('my', name, _lore.byId.keys),
      name: name,
      tags: _tags,
      text: _text.text.trim(),
      links: _links,
    );
    return item == null ? addMyEntry(data, entry) : replaceMyEntry(data, entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.item == null ? l10n.newLoreEntry : l10n.editItem),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isBook)
                Text(widget.item!.name, style: theme.textTheme.titleMedium)
              else ...[
                TextField(
                  controller: _name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.loreName),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _text,
                  minLines: 4,
                  maxLines: 10,
                  decoration: InputDecoration(labelText: l10n.noteText),
                  onChanged: (_) => setState(() {}), // refreshes the suggestions
                ),
              ],
              const SizedBox(height: 16),
              Text(l10n.loreTags, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final tag in _lore.tags)
                  FilterChip(
                    avatar: TagDot(_lore.colorOf(tag.id)),
                    label: Text(tag.name),
                    selected: _tags.contains(tag.id),
                    // A tag the book gave cannot be taken away.
                    onSelected: _bookTags.contains(tag.id)
                        ? null
                        : (on) => _toggleTag(tag.id, on),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.loreNewTag),
                  onPressed: _newTag,
                ),
              ]),
              const SizedBox(height: 16),
              Text(l10n.loreLinks, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final id in _links)
                  InputChip(
                    label: Text(_lore.byId[id]?.name ?? id),
                    onDeleted: _bookLinks.contains(id)
                        ? null
                        : () => setState(() => _links.remove(id)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.loreAddLink),
                  onPressed: _addLink,
                ),
              ]),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.loreSuggested, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final id in _suggestions)
                    ActionChip(
                      label: Text(_lore.byId[id]?.name ?? id),
                      onPressed: () => setState(() => _links.add(id)),
                    ),
                ]),
              ],
              if (_isBook) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(labelText: l10n.loreNote),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _canSave ? () => Navigator.pop(context, _result()) : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
