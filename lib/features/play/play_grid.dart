import 'dart:async';

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/play_items.dart';
import '../../character/play_layout.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/device_class.dart';
import 'add_widget_sheet.dart';
import 'layouts_sheet.dart';
import 'play_widget_card.dart';

/// The Play tab: the character's widgets on a grid of cells. The cells are
/// always drawn faintly. Long press a widget to edit: drag a widget by its
/// handle, resize it by the corner, change titles and items. Dragging snaps to
/// cells; widgets in the way are pushed down.
class PlayGrid extends ConsumerStatefulWidget {
  const PlayGrid({
    super.key,
    required this.character,
    required this.rules,
    required this.editing,
    required this.onEditingChanged,
  });

  final Character character;
  final RulesData rules;
  final bool editing;
  final void Function(bool editing) onEditingChanged;

  @override
  ConsumerState<PlayGrid> createState() => _PlayGridState();
}

class _PlayGridState extends ConsumerState<PlayGrid> {
  // Cells are small squares (about 36 px); a widget covers many of them.
  static const _gap = 2.0;
  static const _maxPageWidth = 1400.0;

  /// Empty rows shown under the last widget, to drop widgets into.
  static const _spareRows = 3;

  static const _columns = {
    DeviceClass.phone: 10,
    DeviceClass.tablet: 20,
    DeviceClass.desktop: 32,
  };

  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();

  // While an item is dragged near the top or bottom edge, a timer scrolls.
  Offset? _itemDragAt;
  Timer? _scrollTimer;

  // A widget being moved or resized: where all tiles were when the finger
  // went down, how far it has moved, and what the tiles look like now.
  List<PlayTile>? _before;
  Offset _moved = Offset.zero;
  List<PlayTile>? _preview;

  @override
  void initState() {
    super.initState();
    _fillDefaultWidgets();
  }

  @override
  void didUpdateWidget(PlayGrid old) {
    super.didUpdateWidget(old);
    if (old.character != widget.character) _preview = null;
    _fillDefaultWidgets();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Character get _character => widget.character;
  List<PlayWidgetData> get _widgets => _character.playWidgets ?? const [];

  /// A character that never opened the Play tab gets its default widgets once.
  void _fillDefaultWidgets() {
    if (_character.playWidgets != null) return;
    Future.microtask(() => _saveWidgets(
        materializeWidgets(_character, widget.rules)));
  }

  void _saveWidgets(List<PlayWidgetData> widgets) => ref
      .read(charactersProvider.notifier)
      .save(_character.copyWith(playWidgets: widgets));

  void _saveTiles(DeviceClass device, List<PlayTile> tiles) => ref
      .read(charactersProvider.notifier)
      .save(withLayout(_character, device, tiles));

  // ---- Moving and resizing a widget ----

  void _gestureStart(List<PlayTile> tiles) {
    _before = tiles;
    _moved = Offset.zero;
  }

  void _gestureUpdate(String id, bool resize, Offset change, Offset pitch,
      int columns) {
    final before = _before;
    if (before == null) return;
    _moved += change;
    final dx = (_moved.dx / pitch.dx).round();
    final dy = (_moved.dy / pitch.dy).round();
    final tile = before.firstWhere((t) => t.widget == id);

    setState(() => _preview = resize
        ? resizeTile(before, id, tile.width + dx, tile.height + dy, columns)
        : moveTile(before, id, tile.x + dx, tile.y + dy, columns));
  }

  void _gestureEnd(DeviceClass device) {
    final result = _preview;
    _before = null;
    if (result != null) _saveTiles(device, result);
  }

  // ---- Edit bar actions ----

  Future<void> _addWidget() => addWidget(context, ref, _character, widget.rules);

  void _showLayouts() {
    final character = _character;
    void save(Character changed) =>
        ref.read(charactersProvider.notifier).save(changed);

    showLayoutsSheet(
      context,
      presets: character.playPresets ?? const [],
      onSave: (name) =>
          save(character.copyWith(playPresets: savePreset(character, name))),
      onLoad: (preset) => save(loadPreset(character, preset)),
      onRename: (preset, name) => save(character.copyWith(
          playPresets: renamePreset(character, preset.name, name))),
      onDelete: (preset) => save(character.copyWith(
          playPresets: removePreset(character, preset.name))),
    );
  }

  Future<void> _resetLayout() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context,
        title: l10n.resetLayout,
        body: l10n.resetLayoutBody,
        confirmLabel: l10n.resetLayout);
    if (!ok) return;
    // Back to the defaults: widgets, items, titles, styles and places on
    // every screen size. Saved layouts are kept.
    ref.read(charactersProvider.notifier).save(_character.copyWith(
          playWidgets: materializeWidgets(_character, widget.rules),
          playLayouts: const {},
        ));
  }

  Future<void> _deleteWidget(PlayWidgetData data) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context,
        title: l10n.deleteWidgetTitle(data.title),
        body: l10n.deleteWidgetBody,
        confirmLabel: l10n.delete);
    if (ok) {
      _saveWidgets([
        for (final w in _widgets)
          if (w.id != data.id) w,
      ]);
    }
  }

  /// Called while an item is dragged (null when it is dropped).
  void _onItemDrag(Offset? at) {
    _itemDragAt = at;
    if (at == null) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    } else {
      _scrollTimer ??= Timer.periodic(
          const Duration(milliseconds: 16), (_) => _scrollNearEdge());
    }
  }

  /// Scrolls the page when the dragged item is near the top or bottom edge:
  /// the closer to the edge, the faster.
  void _scrollNearEdge() {
    const edge = 90.0;
    final at = _itemDragAt;
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (at == null || box == null || !_scroll.hasClients) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    var by = 0.0;
    if (at.dy < top + edge) by = -(top + edge - at.dy) / edge;
    if (at.dy > bottom - edge) by = (at.dy - (bottom - edge)) / edge;
    if (by == 0) return;

    final step = clampDouble(by, -1, 1) * 18;
    _scroll.jumpTo(clampDouble(
        _scroll.offset + step, 0, _scroll.position.maxScrollExtent));
  }

  // ---- Drawing ----

  @override
  Widget build(BuildContext context) {
    final device = deviceClassFor(MediaQuery.sizeOf(context).width);
    final columns = _columns[device]!;
    final tiles = _preview ??
        placementsFor(_character, widget.rules, device, _widgets, columns);

    return Column(children: [
      if (widget.editing) _editBar(device),
      Expanded(
        child: SingleChildScrollView(
          key: _viewportKey,
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxPageWidth),
              child: LayoutBuilder(builder: (context, constraints) {
                final cell =
                    (constraints.maxWidth - (columns - 1) * _gap) / columns;
                return _stack(context, device, columns, cell, tiles);
              }),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _editBar(DeviceClass device) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          IconButton(
            tooltip: l10n.addWidget,
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _addWidget,
          ),
          IconButton(
            tooltip: l10n.savedLayouts,
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: _showLayouts,
          ),
          IconButton(
            tooltip: l10n.resetLayout,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _resetLayout(),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => widget.onEditingChanged(false),
            child: Text(l10n.done),
          ),
        ]),
      ),
    );
  }

  Widget _stack(BuildContext context, DeviceClass device, int columns,
      double cell, List<PlayTile> tiles) {
    final pitch = Offset(cell + _gap, cell + _gap);
    final rows =
        layoutBottom(tiles) + (widget.editing ? _spareRows : 1);

    // The widget being dragged is drawn last, so it is on top.
    final activeId = _before == null ? null : _activeId;
    final ordered = [
      ...tiles.where((t) => t.widget != activeId),
      ...tiles.where((t) => t.widget == activeId),
    ];

    return SizedBox(
      height: rows * pitch.dy - _gap,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CellsPainter(
              columns: columns,
              rows: rows,
              cell: cell,
              gap: _gap,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        for (final tile in ordered)
          AnimatedPositioned(
            key: ValueKey(tile.widget),
            duration: const Duration(milliseconds: 60),
            left: tile.x * pitch.dx,
            top: tile.y * pitch.dy,
            width: tile.width * pitch.dx - _gap,
            height: tile.height * pitch.dy - _gap,
            child: _tile(context, device, columns, pitch, tile, tiles),
          ),
      ]),
    );
  }

  String? _activeId;

  Widget _tile(BuildContext context, DeviceClass device, int columns,
      Offset pitch, PlayTile tile, List<PlayTile> tiles) {
    final data = _widgets.where((w) => w.id == tile.widget).firstOrNull;
    if (data == null) return const SizedBox.shrink();

    Widget handle({required bool resize, required Widget icon}) =>
        GestureDetector(
          onPanStart: (_) {
            _activeId = tile.widget;
            _gestureStart(tiles);
          },
          onPanUpdate: (details) => _gestureUpdate(
              tile.widget, resize, details.delta, pitch, columns),
          onPanEnd: (_) => _gestureEnd(device),
          child: icon,
        );

    return GestureDetector(
      onLongPress:
          widget.editing ? null : () => widget.onEditingChanged(true),
      child: Stack(children: [
        Positioned.fill(
          child: PlayWidgetCard(
            data: data,
            widgets: _widgets,
            character: _character,
            rules: widget.rules,
            editing: widget.editing,
            onChanged: _saveWidgets,
            onDelete: () => _deleteWidget(data),
            onItemDrag: _onItemDrag,
            moveHandle: handle(
              resize: false,
              icon: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.open_with),
              ),
            ),
          ),
        ),
        if (widget.editing)
          Positioned(
            right: 0,
            bottom: 0,
            child: handle(
              resize: true,
              icon: Container(
                width: 32,
                height: 32,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.south_east, size: 20),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Draws one faint rounded square for every cell of the grid.
class _CellsPainter extends CustomPainter {
  const _CellsPainter({
    required this.columns,
    required this.rows,
    required this.cell,
    required this.gap,
    required this.color,
  });

  final int columns;
  final int rows;
  final double cell;
  final double gap;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.12);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(column * (cell + gap), row * (cell + gap), cell, cell),
            const Radius.circular(3),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CellsPainter old) =>
      old.columns != columns ||
      old.rows != rows ||
      old.cell != cell ||
      old.color != color;
}
