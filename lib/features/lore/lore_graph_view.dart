import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/lore.dart';
import '../../character/lore_data.dart';
import '../../l10n/app_localizations.dart';
import '../play/play_info_card.dart';
import '../play/play_widget_card.dart';
import 'lore_providers.dart';
import 'lore_widgets.dart';

// The graph is a corkboard of tiles on an endless area. Graph coordinates
// (what is saved) have (0, 0) in the middle of a huge canvas; _origin moves
// them to canvas coordinates.
const _origin = 50000.0;
const _canvasSize = 2 * _origin;
const _minScale = 0.1;
const _maxScale = 2.5;

const _pinRoom = 16.0; // space above a tile for its pin
const _pinHit = 32.0; // the tappable square around a pin

/// The graph: the entries the player pinned, as tiles on a corkboard. A tile
/// is a Play widget that takes only free items; its pin is the end of the
/// strings (the player's own links between two tiles). Pan and zoom the area
/// as far as you like. Tap a title for the entry's card, a pin to start a
/// string. The pencil in the app bar turns on edit mode: items, tile size and
/// place can then be changed, like in the Play tab.
class LoreGraphView extends ConsumerStatefulWidget {
  const LoreGraphView({super.key, required this.lore, required this.character});

  final LoreContext lore;
  final Character character;

  @override
  ConsumerState<LoreGraphView> createState() => _LoreGraphViewState();
}

class _LoreGraphViewState extends ConsumerState<LoreGraphView> {
  final _controller = TransformationController();

  // Where a tile is while it is being moved or resized (saved when the
  // finger lifts).
  final _live = <String, Rect>{};

  String? _linkFrom; // set while the player picks the pin to tie a string to
  bool _centered = false;
  Size _viewport = Size.zero;

  LoreContext get _lore => widget.lore;
  double get _scale => _controller.value.getMaxScaleOnAxis();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ view

  /// Zoom and pan so that all tiles are in view (or the middle of the graph,
  /// when there are none).
  void _fit() {
    final rects = [for (final n in _lore.data.nodes) n.rect];
    var scale = 1.0;
    var center = Offset.zero;
    if (rects.isNotEmpty) {
      final box = rects.reduce((a, b) => a.expandToInclude(b)).inflate(60);
      scale = math.min(
          1.0, math.min(_viewport.width / box.width, _viewport.height / box.height));
      scale = math.max(_minScale, scale);
      center = box.center;
    }
    final at = (center + const Offset(_origin, _origin)) * scale;
    _controller.value = Matrix4(scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, 1, 0,
        _viewport.width / 2 - at.dx, _viewport.height / 2 - at.dy, 0, 1);
  }

  void _fitOnce() {
    if (_centered) return;
    _centered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
  }

  // ------------------------------------------------------------------ moving

  void _move(String id, Rect rect, Offset delta) =>
      setState(() => _live[id] = (_live[id] ?? rect).shift(delta / _scale));

  void _resize(String id, Rect rect, Offset delta) {
    final r = _live[id] ?? rect;
    final d = delta / _scale;
    setState(() => _live[id] = Rect.fromLTWH(r.left, r.top,
        math.max(minTileWidth, r.width + d.dx), math.max(minTileHeight, r.height + d.dy)));
  }

  /// Saves the place and size a tile has now.
  Future<void> _drop(String id) async {
    final rect = _live[id];
    if (rect == null) return;
    var data = moveNode(_lore.data, id, rect.topLeft);
    data = resizeNode(data, id, rect.size);
    await saveLore(ref, data);
    if (mounted) setState(() => _live.remove(id));
  }

  // ------------------------------------------------------------------ taps

  void _tapPin(String id) {
    final from = _linkFrom;
    if (from == null) {
      setState(() => _linkFrom = id);
      return;
    }
    setState(() => _linkFrom = null);
    if (from != id) _askStringLabel(from, id);
  }

  void _tapTitle(String id) => _linkFrom == null ? _showCard(id) : _tapPin(id);

  Future<void> _askStringLabel(String from, String to) async {
    final label = await _askText(AppLocalizations.of(context).loreLabelOptional, '');
    if (label == null) return;
    await saveLore(
      ref,
      addString(_lore.data,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          from: from,
          to: to,
          label: label),
    );
  }

  /// A small dialog with one text field. Null when cancelled.
  Future<String?> _askText(String title, String initial) async {
    final l10n = AppLocalizations.of(context);
    final field = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: field,
          autofocus: true,
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, field.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    // Not disposed here: the dialog is still fading out and its text field
    // uses the controller (an Esc press crashed with a disposed controller).
    // A controller without listeners needs no dispose.
    return result;
  }

  /// The card of a node (pinned entry) or of a bubble (entry not on the graph).
  void _showCard(String id) {
    final item = _lore.byId[id];
    if (item == null) return;
    final l10n = AppLocalizations.of(context);
    final pinned = _lore.pinned.contains(id);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        // Closes the card, then does [action].
        VoidCallback then(VoidCallback action) => () {
              Navigator.pop(sheetContext);
              action();
            };

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 8),
                TagChips(lore: _lore, tagIds: item.tags),
                const SizedBox(height: 8),
                Text(item.text, maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.tonal(
                    onPressed: then(() => openInCodex(ref, id)),
                    child: Text(l10n.loreOpenInCodex),
                  ),
                  if (pinned) ...[
                    OutlinedButton(
                      onPressed: then(() => setState(() => _linkFrom = id)),
                      child: Text(l10n.loreLinkTo),
                    ),
                    OutlinedButton(
                      onPressed: then(
                          () => saveLore(ref, unpinEntry(_lore.data, id))),
                      child: Text(l10n.loreRemoveFromGraph),
                    ),
                  ] else
                    OutlinedButton(
                      onPressed: then(() => saveLore(
                          ref, pinEntry(_lore.data, id, _lore.byId))),
                      child: Text(l10n.loreAddToGraph),
                    ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Edit the label of a string, or delete it.
  Future<void> _editString(GraphString string) async {
    final l10n = AppLocalizations.of(context);
    final title = '${_lore.byId[string.from]?.name ?? ''} – ${_lore.byId[string.to]?.name ?? ''}';
    final field = TextEditingController(text: string.label);

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.loreLabelOptional),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'delete'),
            child: Text(l10n.delete),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final label = field.text.trim(); // controller not disposed: see _askText

    if (action == 'delete') {
      await saveLore(ref, removeString(_lore.data, string.id));
    } else if (action == 'save') {
      await saveLore(ref, setStringLabel(_lore.data, string.id, label));
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editing = ref.watch(loreEditingProvider);
    final info = ref.watch(playInfoProvider);
    final widgets = nodeWidgets(_lore.data, _lore.byId);
    final nodes = [
      for (final n in _lore.data.nodes)
        if (_lore.byId.containsKey(n.entryId)) n,
    ];
    final rects = {for (final n in nodes) n.entryId: _live[n.entryId] ?? n.rect};

    return LayoutBuilder(builder: (context, constraints) {
      _viewport = constraints.biggest;
      _fitOnce();

      return Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _CorkPainter(
                controller: _controller,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ),
        InteractiveViewer(
          transformationController: _controller,
          constrained: false, // the canvas is much bigger than the screen
          minScale: _minScale,
          maxScale: _maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity), // endless
          child: SizedBox(
            width: _canvasSize,
            height: _canvasSize,
            child: _board(context, widgets, rects, editing),
          ),
        ),
        if (nodes.isEmpty)
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.loreGraphEmpty, textAlign: TextAlign.center),
              ),
            ),
          ),
        if (_linkFrom != null)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Card(
              child: ListTile(
                title: Text(l10n.loreLinkPrompt(_lore.byId[_linkFrom]?.name ?? '')),
                trailing: TextButton(
                  onPressed: () => setState(() => _linkFrom = null),
                  child: Text(l10n.cancel),
                ),
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: null,
            tooltip: l10n.loreFitView,
            onPressed: _fit,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
        if (info != null) PlayInfoCard(info: info),
      ]);
    });
  }

  Offset _onCanvas(Offset p) => p + const Offset(_origin, _origin);

  /// The canvas: strings under the tiles, the tiles on top.
  Widget _board(BuildContext context, List<PlayWidgetData> widgets,
      Map<String, Rect> rects, bool editing) {
    final strings = [
      for (final s in _lore.data.strings)
        if (rects.containsKey(s.from) && rects.containsKey(s.to)) s,
    ];
    Offset pinOf(String id) => _onCanvas(Offset(rects[id]!.center.dx, rects[id]!.top));

    return Stack(children: [
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _StringsPainter(
                [for (final s in strings) (pinOf(s.from), pinOf(s.to))]),
          ),
        ),
      ),
      for (final w in widgets) _tile(context, w, widgets, rects[w.id]!, editing),
      for (final s in strings) _stringHandle(s, pinOf(s.from), pinOf(s.to)),
    ]);
  }

  /// The tap target in the middle of a string: its label, or a small dot.
  Widget _stringHandle(GraphString s, Offset from, Offset to) {
    final middle = _stringMiddle(from, to);
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: middle.dx - 50,
      top: middle.dy - 14,
      width: 100,
      height: 28,
      child: Center(
        child: GestureDetector(
          onTap: () => _editString(s),
          child: s.label.isEmpty
              ? CircleAvatar(radius: 7, backgroundColor: _stringColor)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: _stringColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                ),
        ),
      ),
    );
  }

  /// One tile: the Play card of the entry, with a pin on top and, in edit
  /// mode, a handle to move it (in the card's title row) and one to resize it.
  Widget _tile(BuildContext context, PlayWidgetData w, List<PlayWidgetData> all,
      Rect rect, bool editing) {
    final id = w.id;
    final topLeft = _onCanvas(rect.topLeft);

    final card = PlayWidgetCard(
      data: w,
      widgets: all,
      character: widget.character,
      rules: _lore.rules,
      editing: editing,
      onChanged: (changed) => saveLore(ref, applyNodeWidgets(_lore.data, changed)),
      onDelete: () => saveLore(ref, unpinEntry(_lore.data, id)),
      onItemDrag: (_) {},
      renamable: false,
      freeOnly: true,
      onTitleTap: () => _tapTitle(id),
      footer: _footer(id),
      moveHandle: GestureDetector(
        onPanUpdate: (d) => _move(id, rect, d.delta),
        onPanEnd: (_) => _drop(id),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.drag_indicator, size: 20),
        ),
      ),
    );

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy - _pinRoom,
      width: rect.width,
      height: rect.height + _pinRoom,
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          top: _pinRoom,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 3)),
              ],
            ),
            child: card,
          ),
        ),
        if (editing)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (d) => _resize(id, rect, d.delta),
              onPanEnd: (_) => _drop(id),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.south_east, size: 18),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: rect.width / 2 - _pinHit / 2,
          top: 0,
          width: _pinHit,
          height: _pinHit,
          child: _pin(id),
        ),
      ]),
    );
  }

  Widget _pin(String id) {
    final active = _linkFrom == id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapPin(id),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [Color(0xFFFF8A80), Color(0xFFC62828)],
            ),
            border: active
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                : null,
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 2)),
            ],
          ),
        ),
      ),
    );
  }

  /// Under a tile's items: its tag colors, then its weak links (links to
  /// entries that are not on the graph). A weak link opens that entry's card.
  Widget? _footer(String id) {
    final item = _lore.byId[id]!;
    final weak = [
      for (final link in item.links)
        if (_lore.byId.containsKey(link) && !_lore.pinned.contains(link)) link,
    ];
    if (item.tags.isEmpty && weak.isEmpty) return null;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final tag in item.tags)
            Tooltip(
              message: _lore.tagName(tag),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Center(child: TagDot(_lore.colorOf(tag), size: 14)),
              ),
            ),
          for (final link in weak)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: ActionChip(
                  avatar: const Icon(Icons.link, size: 14),
                  label: Text(_lore.byId[link]!.name, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showCard(link),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------- painters

const _stringColor = Color(0xFFB71C1C); // red twine

/// How far a string hangs down in the middle.
double _hang(Offset a, Offset b) => math.min(60.0, (a - b).distance * 0.15);

/// The middle of the string between two pins (it hangs a little).
Offset _stringMiddle(Offset a, Offset b) => (a + b) / 2 + Offset(0, _hang(a, b));

/// The strings: a hanging curve from pin to pin.
class _StringsPainter extends CustomPainter {
  _StringsPainter(this.lines);

  final List<(Offset, Offset)> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final twine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = _stringColor;
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.black26;

    for (final (a, b) in lines) {
      // A curve whose middle point is _stringMiddle.
      final control = (a + b) / 2 + Offset(0, 2 * _hang(a, b));
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);
      canvas.drawPath(path.shift(const Offset(2, 3)), shadow);
      canvas.drawPath(path, twine);
    }
  }

  @override
  bool shouldRepaint(_StringsPainter old) => true; // cheap: a few lines
}

/// The cork behind the tiles: a brown surface with speckles. It is painted
/// in screen space from the view's pan and zoom, so it never ends.
class _CorkPainter extends CustomPainter {
  _CorkPainter({required this.controller, required this.dark})
      : super(repaint: controller);

  final TransformationController controller;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = dark ? const Color(0xFF5A4630) : const Color(0xFFC9A875);
    final speckles = dark
        ? const [Color(0xFF3E2F20), Color(0xFF76603F)]
        : const [Color(0xFF8D6E3F), Color(0xFFE2C79A)];
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final m = controller.value;
    final scale = m.getMaxScaleOnAxis();
    final tx = m.storage[12];
    final ty = m.storage[13];

    // Cells of speckles in graph space; far out they get bigger so that there
    // are never too many to draw.
    var cell = 48.0;
    while (cell * scale < 30) {
      cell *= 2;
    }
    final left = (-tx / scale / cell).floor();
    final right = ((size.width - tx) / scale / cell).ceil();
    final top = (-ty / scale / cell).floor();
    final bottom = ((size.height - ty) / scale / cell).ceil();

    final paint = Paint();
    for (var cy = top; cy <= bottom; cy++) {
      for (var cx = left; cx <= right; cx++) {
        final h = _hash(cx, cy);
        final x = (cx + (h & 0xff) / 255) * cell * scale + tx;
        final y = (cy + ((h >> 8) & 0xff) / 255) * cell * scale + ty;
        paint.color = speckles[(h >> 16) & 1];
        canvas.drawCircle(Offset(x, y), 1.2 + ((h >> 17) & 3) * 0.5, paint);
      }
    }
  }

  /// A number that looks random but is always the same for a cell.
  int _hash(int x, int y) {
    var h = (x * 73856093) ^ (y * 19349663);
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  @override
  bool shouldRepaint(_CorkPainter old) => old.dark != dark;
}
