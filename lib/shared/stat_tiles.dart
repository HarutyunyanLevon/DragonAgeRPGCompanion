import 'package:flutter/material.dart';

import 'shield_plate.dart';
import 'theme_look.dart';

/// One number of the character sheet: a small label over a big value. A tile
/// with an [info] can be tapped to read it. A [shield] tile is drawn as a
/// shield in themes that have shields (Defense, Armor, Speed).
class StatTile {
  const StatTile({
    required this.label,
    required this.value,
    this.info,
    this.shield = false,
  });

  final String label;
  final String value;
  final Widget? info;
  final bool shield;
}

/// A row of tiles like the circles on the paper sheet. Tapping a tile shows
/// its description under the row (one at a time); tap again to close it.
class StatTiles extends StatefulWidget {
  const StatTiles({super.key, required this.tiles});

  final List<StatTile> tiles;

  @override
  State<StatTiles> createState() => _StatTilesState();
}

class _StatTilesState extends State<StatTiles> {
  String? _openLabel; // by label, so filtering the tiles keeps it right

  @override
  Widget build(BuildContext context) {
    final open = widget.tiles.where((t) => t.label == _openLabel).firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          for (final tile in widget.tiles)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _tile(context, tile, tile == open),
              ),
            ),
        ]),
        if (open?.info != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: open!.info!,
          ),
      ]),
    );
  }

  Widget _tile(BuildContext context, StatTile tile, bool isOpen) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final look = ThemeLook.of(context);

    final onTap = tile.info == null
        ? null
        : () => setState(() => _openLabel = isOpen ? null : tile.label);

    if (tile.shield && look.statShape != StatShape.box) {
      return ShieldPlate(
          shape: look.statShape,
          label: tile.label,
          value: tile.value,
          selected: isOpen,
          onTap: onTap);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(look.radius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isOpen ? colors.primary.withValues(alpha: 0.2) : null,
          border: Border.all(
              color: tile.info == null ? colors.outlineVariant : colors.outline),
          borderRadius: BorderRadius.circular(look.radius),
        ),
        child: Column(children: [
          Text(tile.label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall),
          Text(tile.value, style: text.titleLarge),
        ]),
      ),
    );
  }
}
