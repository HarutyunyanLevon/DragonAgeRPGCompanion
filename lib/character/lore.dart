import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import '../rules/models/lore.dart';
import '../rules/slug.dart';
import '../shared/name_linker.dart';
import 'character.dart';
import 'lore_data.dart';

// Pure functions of the Lore tab (no widgets): the entries as shown, tags and
// colors, and every change of the player's lore and graph. Each change takes
// a [LoreData] and returns a new one.

/// One entry as the Lore tab shows it: a book entry with the player's
/// additions, or an entry of the player's own.
class LoreItem {
  const LoreItem({
    required this.id,
    required this.name,
    required this.section,
    required this.tags,
    required this.text,
    required this.links,
    required this.isMine,
    this.note = '',
  });

  final String id;
  final String name;

  /// Chapter section of a book entry; empty for the player's own entries.
  final String section;
  final List<String> tags;
  final String text;
  final List<String> links;
  final bool isMine;

  /// The player's private note on a book entry.
  final String note;
}

/// Own entries first, then the book entries (in book order).
List<LoreItem> buildLoreItems(List<LoreEntry> book, LoreData data) {
  final additions = {for (final a in data.additions) a.entryId: a};
  return [
    for (final e in data.myEntries)
      LoreItem(
        id: e.id,
        name: e.name,
        section: '',
        tags: e.tags,
        text: e.text,
        links: e.links,
        isMine: true,
      ),
    for (final e in book)
      LoreItem(
        id: e.id,
        name: e.name,
        section: e.section,
        tags: _union(e.tags, additions[e.id]?.tags),
        text: e.summary,
        links: _union(e.links, additions[e.id]?.links),
        isMine: false,
        note: additions[e.id]?.note ?? '',
      ),
  ];
}

List<String> _union(List<String> first, List<String>? second) =>
    [...first, ...?second?.where((s) => !first.contains(s))];

/// [base], or [base]-2, [base]-3... when [taken] already has it.
String uniqueId(String base, Iterable<String> taken) {
  final used = taken.toSet();
  if (!used.contains(base)) return base;
  var n = 2;
  while (used.contains('$base-$n')) {
    n++;
  }
  return '$base-$n';
}

// ---------------------------------------------------------------- tags, colors

/// Book tags first, then the player's own.
List<LoreTag> allTags(List<LoreTag> bookTags, LoreData data) =>
    [...bookTags, ...data.myTags];

/// The colors a tag can get by default and the picker starts with (ARGB).
const lorePalette = <int>[
  0xFF64B5F6, // blue
  0xFFFFB74D, // orange
  0xFF81C784, // green
  0xFFBA68C8, // purple
  0xFFFFD54F, // yellow
  0xFF90A4AE, // grey
  0xFFE57373, // red
  0xFF4DB6AC, // teal
  0xFFF06292, // pink
  0xFFA1887F, // brown
];

/// Tag id -> color. A tag the player has not colored gets the palette color
/// at its position in the list.
Map<String, int> tagColorMap(List<LoreTag> tags, LoreData data) => {
      for (var i = 0; i < tags.length; i++)
        tags[i].id: data.tagColors[tags[i].id] ?? lorePalette[i % lorePalette.length],
    };

/// "#C9A227" or "C9A227" -> ARGB number; null when it is not six hex digits.
int? parseHexColor(String text) {
  final hex = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return 0xFF000000 | int.parse(hex, radix: 16);
}

LoreData setTagColor(LoreData data, String tagId, int color) =>
    data.copyWith(tagColors: {...data.tagColors, tagId: color});

LoreData addPaletteColor(LoreData data, int color) =>
    lorePalette.contains(color) || data.palette.contains(color)
        ? data
        : data.copyWith(palette: [...data.palette, color]);

/// A new tag of the player's, with its color.
LoreData addTag(LoreData data, LoreTag tag, int color) => setTagColor(
    data.copyWith(myTags: [...data.myTags, tag]), tag.id, color);

/// Removes one of the player's tags from everything that carried it.
LoreData removeTag(LoreData data, String tagId) {
  List<String> without(List<String> tags) =>
      [for (final t in tags) if (t != tagId) t];
  return data.copyWith(
    myTags: [for (final t in data.myTags) if (t.id != tagId) t],
    tagColors: {...data.tagColors}..remove(tagId),
    myEntries: [
      for (final e in data.myEntries)
        MyLoreEntry(
            id: e.id,
            name: e.name,
            tags: without(e.tags),
            text: e.text,
            links: e.links),
    ],
    additions: [
      for (final a in data.additions)
        LoreAddition(
            entryId: a.entryId,
            tags: without(a.tags),
            links: a.links,
            note: a.note),
    ],
  );
}

// -------------------------------------------------------------------- entries

LoreData addMyEntry(LoreData data, MyLoreEntry entry) =>
    data.copyWith(myEntries: [...data.myEntries, entry]);

LoreData replaceMyEntry(LoreData data, MyLoreEntry entry) => data.copyWith(
      myEntries: [
        for (final e in data.myEntries) e.id == entry.id ? entry : e,
      ],
    );

/// Deletes an own entry, its node and strings, and every link to it.
LoreData removeMyEntry(LoreData data, String id) {
  List<String> without(List<String> links) =>
      [for (final l in links) if (l != id) l];
  return unpinEntry(data, id).copyWith(
    myEntries: [
      for (final e in data.myEntries)
        if (e.id != id)
          MyLoreEntry(
              id: e.id,
              name: e.name,
              tags: e.tags,
              text: e.text,
              links: without(e.links)),
    ],
    additions: [
      for (final a in data.additions)
        LoreAddition(
            entryId: a.entryId,
            tags: a.tags,
            links: without(a.links),
            note: a.note),
    ],
  );
}

/// Sets what the player added to a book entry. An empty addition is dropped.
LoreData setAddition(LoreData data, LoreAddition addition) {
  final others = [
    for (final a in data.additions)
      if (a.entryId != addition.entryId) a,
  ];
  return data.copyWith(
      additions: addition.isEmpty ? others : [...others, addition]);
}

// ---------------------------------------------------------------- name linking

/// The words of a text that may name an entry: the name itself, without a
/// "(...)" part and a leading "The", and the part before the first comma
/// ("Moira, the Rebel Queen" -> "Moira"). Names shorter than 3 letters are
/// left out.
List<String> loreLinkNames(String name) {
  final plain = name.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
  final names = {
    plain,
    plain.replaceFirst(RegExp(r'^The\s+', caseSensitive: false), ''),
    plain.split(',').first,
  };
  return [for (final n in names) if (n.length >= 3) n];
}

/// Lower-case link name -> entry id. The first entry with a name keeps it
/// (the player's own entries come first).
Map<String, String> loreNameMap(List<LoreItem> items) {
  final map = <String, String>{};
  for (final item in items) {
    for (final name in loreLinkNames(item.name)) {
      map.putIfAbsent(name.toLowerCase(), () => item.id);
    }
  }
  return map;
}

/// Ids of the entries whose names appear in [text] (for suggested links).
List<String> suggestLinks(String text, String selfId, NameLinker linker) =>
    [for (final m in linker.find(text, selfKey: selfId)) m.target];

// ---------------------------------------------------------------------- graph

// The graph is endless: nodes have no limits, only a size.

const minTileWidth = 140.0;
const minTileHeight = 100.0;

/// Free space kept between tiles when they are placed or organized.
const _tileGap = 30.0;

/// Extra space between two groups of linked tiles when organizing.
const _groupGap = 80.0;

/// Puts an entry on the graph as a tile. It lands next to a pinned entry it
/// is linked with (in either direction), else near the middle of the tiles,
/// on a free spot. Already pinned or unknown entries change nothing.
LoreData pinEntry(LoreData data, String id, Map<String, LoreItem> byId) {
  final item = byId[id];
  if (item == null || data.nodes.any((n) => n.entryId == id)) return data;

  // Without a linked tile: around the middle of the tiles (or of the graph).
  const half = Offset(GraphNode.defaultTileWidth / 2, GraphNode.defaultTileHeight / 2);
  var start = (data.nodes.isEmpty ? Offset.zero : _bounds(data.nodes).center) - half;
  for (final node in data.nodes) {
    final linked = item.links.contains(node.entryId) ||
        (byId[node.entryId]?.links.contains(id) ?? false);
    if (linked) {
      start = Offset(node.x, node.y);
      break;
    }
  }

  final spot = _freeSpot(data.nodes, start);
  return data.copyWith(nodes: [...data.nodes, GraphNode(entryId: id, x: spot.dx, y: spot.dy)]);
}

/// The smallest rectangle holding all [nodes].
Rect _bounds(List<GraphNode> nodes) =>
    nodes.map((n) => n.rect).reduce((a, b) => a.expandToInclude(b));

/// The free spot for a new tile that is nearest to [start]: [start] itself,
/// else the cells around it (one tile apart), nearest ring first.
Offset _freeSpot(List<GraphNode> nodes, Offset start) {
  const stepX = GraphNode.defaultTileWidth + _tileGap;
  const stepY = GraphNode.defaultTileHeight + _tileGap;

  bool free(Offset spot) {
    final tile = Rect.fromLTWH(
        spot.dx, spot.dy, GraphNode.defaultTileWidth, GraphNode.defaultTileHeight);
    return nodes.every((n) => !n.rect.overlaps(tile));
  }

  for (var ring = 0; ring < 30; ring++) {
    for (var dy = -ring; dy <= ring; dy++) {
      for (var dx = -ring; dx <= ring; dx++) {
        if (math.max(dx.abs(), dy.abs()) != ring) continue;
        final spot = start + Offset(dx * stepX, dy * stepY);
        if (free(spot)) return spot;
      }
    }
  }
  return start; // everything around is taken
}

LoreData _changeNode(LoreData data, String id, GraphNode Function(GraphNode) change) =>
    data.copyWith(nodes: [for (final n in data.nodes) n.entryId == id ? change(n) : n]);

/// Moves a tile; [topLeft] is where its top-left corner goes.
LoreData moveNode(LoreData data, String id, Offset topLeft) =>
    _changeNode(data, id, (n) => n.copyWith(x: topLeft.dx, y: topLeft.dy));

/// Gives a tile a new size (never below the minimum).
LoreData resizeNode(LoreData data, String id, Size size) => _changeNode(
    data,
    id,
    (n) => n.copyWith(
        width: math.max(minTileWidth, size.width),
        height: math.max(minTileHeight, size.height)));

/// The tiles as Play widgets (id = entry id, title = entry name), so the Play
/// card and its item functions (`addItem`, `moveItem`...) can edit them.
/// Tiles of entries that no longer exist are left out.
List<PlayWidgetData> nodeWidgets(LoreData data, Map<String, LoreItem> byId) => [
      for (final n in data.nodes)
        if (byId.containsKey(n.entryId))
          PlayWidgetData(
              id: n.entryId,
              title: byId[n.entryId]!.name,
              style: n.style,
              items: n.items),
    ];

/// Takes the items and style of [widgets] (the result of editing
/// [nodeWidgets]) back into the tiles.
LoreData applyNodeWidgets(LoreData data, List<PlayWidgetData> widgets) =>
    data.copyWith(nodes: [
      for (final n in data.nodes)
        switch (widgets.where((w) => w.id == n.entryId).firstOrNull) {
          final w? => n.copyWith(items: w.items, style: w.style),
          null => n,
        },
    ]);

/// Takes an entry off the graph, with the strings tied to it.
LoreData unpinEntry(LoreData data, String id) => data.copyWith(
      nodes: [for (final n in data.nodes) if (n.entryId != id) n],
      strings: [
        for (final s in data.strings)
          if (s.from != id && s.to != id) s,
      ],
    );

/// Puts all tiles in tidy rows without overlaps. Tiles that belong together
/// (a string between them, or a link between their entries) stay together,
/// biggest group first, each group starting on a new row. Sizes stay; the
/// whole set stays around the same middle.
LoreData organizeNodes(LoreData data, Map<String, LoreItem> byId) {
  final nodes = data.nodes;
  if (nodes.isEmpty) return data;
  final byEntry = {for (final n in nodes) n.entryId: n};

  // Who is tied to whom.
  final tied = {for (final n in nodes) n.entryId: <String>[]};
  void tie(String a, String b) {
    if (a == b || !byEntry.containsKey(a) || !byEntry.containsKey(b)) return;
    tied[a]!.add(b);
    tied[b]!.add(a);
  }

  for (final s in data.strings) {
    tie(s.from, s.to);
  }
  for (final n in nodes) {
    for (final link in byId[n.entryId]?.links ?? const <String>[]) {
      tie(n.entryId, link);
    }
  }

  // Groups: breadth-first from each tile not seen yet, so neighbours end up
  // next to each other.
  final seen = <String>{};
  final groups = <List<GraphNode>>[];
  for (final first in nodes) {
    if (!seen.add(first.entryId)) continue;
    final queue = [first.entryId];
    for (var i = 0; i < queue.length; i++) {
      for (final id in tied[queue[i]]!) {
        if (seen.add(id)) queue.add(id);
      }
    }
    groups.add([for (final id in queue) byEntry[id]!]);
  }
  int firstIndex(List<GraphNode> g) => nodes.indexOf(g.first);
  groups.sort((a, b) => a.length != b.length
      ? b.length.compareTo(a.length)
      : firstIndex(a).compareTo(firstIndex(b)));

  // Rows as wide as about a square of tiles.
  final perRow = math.max(3, math.sqrt(nodes.length).ceil());
  final rowWidth = perRow * (GraphNode.defaultTileWidth + _tileGap);
  final places = <String, Offset>{};
  var y = 0.0;
  for (final group in groups) {
    var x = 0.0;
    var rowHeight = 0.0;
    for (final n in group) {
      if (x > 0 && x + n.width > rowWidth) {
        y += rowHeight + _tileGap;
        x = 0;
        rowHeight = 0;
      }
      places[n.entryId] = Offset(x, y);
      x += n.width + _tileGap;
      rowHeight = math.max(rowHeight, n.height);
    }
    y += rowHeight + _groupGap;
  }

  // Keep the middle where it was.
  final laidOut = [
    for (final n in nodes) n.copyWith(x: places[n.entryId]!.dx, y: places[n.entryId]!.dy),
  ];
  final shift = _bounds(nodes).center - _bounds(laidOut).center;
  final move = Offset(shift.dx.roundToDouble(), shift.dy.roundToDouble());
  return data.copyWith(nodes: [
    for (final n in laidOut) n.copyWith(x: n.x + move.dx, y: n.y + move.dy),
  ]);
}

/// Draws a string between two nodes. One string per pair: a second one only
/// changes the label of the first.
LoreData addString(LoreData data,
    {required String id,
    required String from,
    required String to,
    String label = ''}) {
  if (from == to) return data;
  final existing = data.strings.where(
      (s) => (s.from == from && s.to == to) || (s.from == to && s.to == from));
  if (existing.isNotEmpty) return setStringLabel(data, existing.first.id, label);
  return data.copyWith(
      strings: [...data.strings, GraphString(id: id, from: from, to: to, label: label)]);
}

LoreData setStringLabel(LoreData data, String id, String label) =>
    data.copyWith(strings: [
      for (final s in data.strings) s.id == id ? s.copyWith(label: label) : s,
    ]);

LoreData removeString(LoreData data, String id) =>
    data.copyWith(strings: [for (final s in data.strings) if (s.id != id) s]);

// ---------------------------------------------------------------- export / import

/// [data] plus what [other] has and [data] does not (same ids are kept as they
/// are in [data]). Used by "Import lore".
LoreData mergeLore(LoreData data, LoreData other) {
  final entryIds = {for (final e in data.myEntries) e.id};
  final tagIds = {for (final t in data.myTags) t.id};
  final additionIds = {for (final a in data.additions) a.entryId};
  final nodeIds = {for (final n in data.nodes) n.entryId};
  final stringIds = {for (final s in data.strings) s.id};

  return LoreData(
    myEntries: [...data.myEntries, for (final e in other.myEntries) if (!entryIds.contains(e.id)) e],
    additions: [
      for (final a in data.additions)
        _mergeAddition(a, other.additions.where((o) => o.entryId == a.entryId)),
      for (final a in other.additions) if (!additionIds.contains(a.entryId)) a,
    ],
    myTags: [...data.myTags, for (final t in other.myTags) if (!tagIds.contains(t.id)) t],
    tagColors: {...other.tagColors, ...data.tagColors},
    palette: [...data.palette, for (final c in other.palette) if (!data.palette.contains(c)) c],
    nodes: [...data.nodes, for (final n in other.nodes) if (!nodeIds.contains(n.entryId)) n],
    strings: [...data.strings, for (final s in other.strings) if (!stringIds.contains(s.id)) s],
  );
}

LoreAddition _mergeAddition(LoreAddition mine, Iterable<LoreAddition> others) {
  if (others.isEmpty) return mine;
  final other = others.first;
  return LoreAddition(
    entryId: mine.entryId,
    tags: _union(mine.tags, other.tags),
    links: _union(mine.links, other.links),
    note: mine.note.isEmpty ? other.note : mine.note,
  );
}

/// An id for a new own entry or tag from its name.
String newLoreId(String prefix, String name, Iterable<String> taken) =>
    uniqueId('$prefix-${slug(name)}', taken);

/// A new own tag called [name], with the next default color. Returns the
/// lore with the tag and the tag itself. [tags] are all tags there are now.
(LoreData, LoreTag) createTag(LoreData data, List<LoreTag> tags, String name) {
  final tag = LoreTag(id: newLoreId('tag', name, tags.map((t) => t.id)), name: name);
  final color = lorePalette[tags.length % lorePalette.length];
  return (addTag(data, tag, color), tag);
}
