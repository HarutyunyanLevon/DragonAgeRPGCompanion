import 'dart:math';

import '../rules/rules_data.dart';
import '../shared/device_class.dart';
import 'character.dart';

/// Where the Play widgets sit on the grid, as pure functions. A tile is a
/// rectangle of cells: column [PlayTile.x], row [PlayTile.y], width, height.
/// Tiles never overlap; when one is dropped on another, the other is pushed
/// down.

/// Size of a widget that was just added (below the others), in cells.
const newTileWidth = 10;
const newTileHeight = 8;

/// The place of every widget on this device class, in the order of [widgets]:
/// the character's own place, else the default place, else a new place below
/// all others. Every tile is kept inside the [columns].
List<PlayTile> placementsFor(Character c, RulesData rules, DeviceClass device,
    List<PlayWidgetData> widgets, int columns) {
  final own = c.playLayouts[device.name] ?? const <PlayTile>[];
  final defaults = rules.defaultLayouts[device.name] ?? const <PlayTile>[];

  PlayTile? find(List<PlayTile> tiles, String id) =>
      tiles.where((t) => t.widget == id).firstOrNull;

  final tiles = <PlayTile>[];
  final unplaced = <String>[];
  for (final w in widgets) {
    final tile = find(own, w.id) ?? find(defaults, w.id);
    if (tile == null) {
      unplaced.add(w.id);
    } else {
      tiles.add(clampTile(tile, columns));
    }
  }

  var bottom = layoutBottom(tiles);
  for (final id in unplaced) {
    tiles.add(PlayTile(
        widget: id, x: 0, y: bottom, width: min(columns, newTileWidth), height: newTileHeight));
    bottom += newTileHeight;
  }

  // Keep the order of [widgets].
  return [for (final w in widgets) tiles.firstWhere((t) => t.widget == w.id)];
}

/// The character with [tiles] as its places on this device class.
Character withLayout(Character c, DeviceClass device, List<PlayTile> tiles) =>
    c.copyWith(playLayouts: {...c.playLayouts, device.name: tiles});

/// The first row below all tiles.
int layoutBottom(List<PlayTile> tiles) =>
    tiles.fold(0, (bottom, t) => max(bottom, t.y + t.height));

/// [value] kept between [low] and [high].
int clampInt(int value, int low, int high) => max(low, min(high, value));

/// [tile] made to fit inside the columns (at least 1 x 1).
PlayTile clampTile(PlayTile tile, int columns) {
  final width = clampInt(tile.width, 1, columns);
  return tile.copyWith(
    width: width,
    height: max(1, tile.height),
    x: clampInt(tile.x, 0, columns - width),
    y: max(0, tile.y),
  );
}

bool tilesOverlap(PlayTile a, PlayTile b) =>
    a.x < b.x + b.width &&
    b.x < a.x + a.width &&
    a.y < b.y + b.height &&
    b.y < a.y + a.height;

/// Resolves overlaps with the tile [anchorId], which stays where it is: every
/// other tile that is in the way is pushed down below what it hits.
List<PlayTile> settle(List<PlayTile> tiles, String anchorId) {
  final others = [
    for (final t in tiles)
      if (t.widget != anchorId) t,
  ]..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

  final placed = [tiles.firstWhere((t) => t.widget == anchorId)];
  for (var tile in others) {
    PlayTile? hit() => placed.where((p) => tilesOverlap(p, tile)).firstOrNull;
    for (var h = hit(); h != null; h = hit()) {
      tile = tile.copyWith(y: h.y + h.height);
    }
    placed.add(tile);
  }
  return [for (final t in tiles) placed.firstWhere((p) => p.widget == t.widget)];
}

/// Moves a tile to column [x], row [y] and pushes tiles in the way down.
List<PlayTile> moveTile(
    List<PlayTile> tiles, String id, int x, int y, int columns) {
  return settle([
    for (final t in tiles)
      t.widget == id ? clampTile(t.copyWith(x: x, y: y), columns) : t,
  ], id);
}

/// Gives a tile a new size and pushes tiles in the way down.
List<PlayTile> resizeTile(
    List<PlayTile> tiles, String id, int width, int height, int columns) {
  return settle([
    for (final t in tiles)
      t.widget == id
          ? clampTile(t.copyWith(width: width, height: height), columns)
          : t,
  ], id);
}
