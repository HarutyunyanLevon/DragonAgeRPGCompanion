import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/play_items.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import 'add_item_sheet.dart';
import 'free_item_dialog.dart';
import 'play_item_view.dart';
import 'shown_item.dart';

/// What is carried while an item is dragged: where it comes from.
class ItemDrag {
  const ItemDrag(this.widgetId, this.index);

  final String widgetId;
  final int index;
}

/// One Play widget: a title and its items, in a box. Items scroll when they
/// do not fit. In edit mode the title can be changed, and items can be
/// dragged (also to other widgets), edited, moved and deleted.
class PlayWidgetCard extends ConsumerWidget {
  const PlayWidgetCard({
    super.key,
    required this.data,
    required this.widgets,
    required this.character,
    required this.rules,
    required this.editing,
    required this.onChanged,
    required this.onDelete,
    required this.onItemDrag,
    this.moveHandle,
  });

  final PlayWidgetData data;

  /// All widgets: items move between them, and every change replaces the list.
  final List<PlayWidgetData> widgets;
  final Character character;
  final RulesData rules;
  final bool editing;
  final void Function(List<PlayWidgetData> widgets) onChanged;
  final VoidCallback onDelete;

  /// Told where the finger is while an item is dragged (for auto-scroll);
  /// null when the item is dropped.
  final void Function(Offset? globalPosition) onItemDrag;

  /// Dragging this moves the whole widget on the grid (edit mode only).
  final Widget? moveHandle;

  static const _gap = 6.0;
  static const _tileMinWidth = 96.0;

  bool get _tiles => data.style == 'tiles';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
            color: editing ? colors.primary : colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        _header(context),
        Expanded(child: _body(context, ref)),
      ]),
    );
  }

  // ---- Header ----

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: editing
            ? Row(children: [
                if (moveHandle != null) moveHandle!,
                Expanded(
                  child: _TitleField(
                    key: ValueKey(data.id),
                    title: data.title,
                    onSaved: (title) =>
                        onChanged(renameWidget(widgets, data.id, title)),
                  ),
                ),
                IconButton(
                  tooltip: _tiles ? l10n.styleList : l10n.styleTiles,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(_tiles ? Icons.view_list : Icons.grid_view),
                  onPressed: () => onChanged(setWidgetStyle(
                      widgets, data.id, _tiles ? 'list' : 'tiles')),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ])
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(data.title,
                      style: text.titleSmall, overflow: TextOverflow.ellipsis),
                ),
              ),
      ),
    );
  }

  // ---- Items ----

  Widget _body(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final inner = constraints.maxWidth - 16;
      final perLine = max(1, ((inner + _gap) / (_tileMinWidth + _gap)).floor());
      final tileWidth = (inner - (perLine - 1) * _gap) / perLine;

      final items = [
        for (var i = 0; i < data.items.length; i++)
          _item(context, ref, i, tileWidth),
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_tiles)
            ..._tileRows(items, perLine)
          else
            ...items,
          if (editing) _addRow(context, ref),
        ]),
      );
    });
  }

  /// Tiles in lines of [perLine]; the tiles of a line share its width, so
  /// every line, also the last, fills the widget.
  List<Widget> _tileRows(List<Widget> tiles, int perLine) => [
        for (var i = 0; i < tiles.length; i += perLine)
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var j = i; j < min(i + perLine, tiles.length); j++) ...[
                if (j > i) const SizedBox(width: _gap),
                Expanded(child: tiles[j]),
              ],
            ]),
          ),
      ];

  Widget _item(BuildContext context, WidgetRef ref, int index, double tileWidth) {
    final item = data.items[index];
    final view = PlayItemView(
      item: item,
      character: character,
      rules: rules,
      tiles: _tiles,
      tileWidth: tileWidth,
      onChanged: (changed) =>
          onChanged(replaceItem(widgets, data.id, index, changed)),
    );
    if (!editing) return view;

    final shown = showItem(context, ref, item, character, rules);
    final menu = _itemMenu(context, ref, index);
    final editable = _tiles
        ? SizedBox(
            width: tileWidth,
            child: Stack(children: [
              AbsorbPointer(child: view),
              Positioned(top: 0, right: 0, child: menu),
            ]),
          )
        : Row(children: [
            Expanded(child: AbsorbPointer(child: view)),
            menu,
          ]);

    // The whole item is the handle: hold briefly, then drag.
    final draggable = LongPressDraggable<ItemDrag>(
      data: ItemDrag(data.id, index),
      delay: const Duration(milliseconds: 150),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragUpdate: (details) => onItemDrag(details.globalPosition),
      onDragEnd: (_) => onItemDrag(null),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(shown.title),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: editable),
      child: editable,
    );

    return _DropSlot(
      onDropped: (drag) => onChanged(
          moveItem(widgets, drag.widgetId, drag.index, data.id, index)),
      line: _tiles ? DropLine.left : DropLine.top,
      child: draggable,
    );
  }

  Widget _itemMenu(BuildContext context, WidgetRef ref, int index) {
    final l10n = AppLocalizations.of(context);
    final item = data.items[index];
    final others = [
      for (final w in widgets)
        if (w.id != data.id) w,
    ];

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (_) => [
        if (freeItemTypes.contains(item.type))
          PopupMenuItem(value: 'edit', child: Text(l10n.editItem)),
        if (others.isNotEmpty)
          PopupMenuItem(value: 'move', child: Text(l10n.moveTo)),
        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
      onSelected: (choice) async {
        switch (choice) {
          case 'edit':
            final changed =
                await editFreeItem(context, type: item.type, existing: item);
            if (changed != null) {
              onChanged(replaceItem(widgets, data.id, index, changed));
            }
          case 'move':
            final target = await _chooseWidget(context, others);
            if (target != null) {
              onChanged(moveItem(
                  widgets, data.id, index, target.id, target.items.length));
            }
          case 'delete':
            onChanged(removeItem(widgets, data.id, index));
        }
      },
    );
  }

  Future<PlayWidgetData?> _chooseWidget(
      BuildContext context, List<PlayWidgetData> others) {
    return showDialog<PlayWidgetData>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(AppLocalizations.of(context).moveTo),
        children: [
          for (final w in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, w),
              child: Text(w.title),
            ),
        ],
      ),
    );
  }

  /// "+ Add item". Also takes dropped items, which go to the end.
  Widget _addRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return _DropSlot(
      onDropped: (drag) => onChanged(moveItem(
          widgets, drag.widgetId, drag.index, data.id, data.items.length)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addItem),
          onPressed: () async {
            final item = await pickItem(context, ref, character, rules);
            if (item != null) onChanged(addItem(widgets, data.id, item));
          },
        ),
      ),
    );
  }
}

/// Where the insert line is drawn while an item hovers over a slot.
enum DropLine { top, left, box }

/// Takes a dropped [ItemDrag] and shows a line where it will land.
class _DropSlot extends StatelessWidget {
  const _DropSlot({
    required this.onDropped,
    required this.child,
    this.line = DropLine.box,
  });

  final void Function(ItemDrag drag) onDropped;
  final Widget child;
  final DropLine line;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return DragTarget<ItemDrag>(
      onAcceptWithDetails: (details) => onDropped(details.data),
      builder: (context, hovering, _) {
        final mark = BorderSide(
            color: hovering.isEmpty ? Colors.transparent : color, width: 3);
        return DecoratedBox(
          decoration: BoxDecoration(
            border: switch (line) {
              DropLine.top => Border(top: mark),
              DropLine.left => Border(left: mark),
              DropLine.box => Border.all(
                  color: hovering.isEmpty ? Colors.transparent : color),
            },
          ),
          child: child,
        );
      },
    );
  }
}

/// The title as a text field. Saves when it loses focus or is submitted.
class _TitleField extends StatefulWidget {
  const _TitleField({super.key, required this.title, required this.onSaved});

  final String title;
  final void Function(String title) onSaved;

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  late final _controller = TextEditingController(text: widget.title);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isNotEmpty && title != widget.title) widget.onSaved(title);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      style: Theme.of(context).textTheme.titleSmall,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
      ),
      onSubmitted: (_) => _save(),
      onTapOutside: (_) => _focus.unfocus(),
    );
  }
}
