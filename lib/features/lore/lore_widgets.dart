import 'package:flutter/material.dart';

import 'lore_providers.dart';

/// A small round dot in a tag's color.
class TagDot extends StatelessWidget {
  const TagDot(this.color, {super.key, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// The tags of an entry as small chips with a colored dot.
class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.lore, required this.tagIds});

  final LoreContext lore;
  final List<String> tagIds;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 6, runSpacing: 4, children: [
        for (final id in tagIds)
          Chip(
            avatar: TagDot(lore.colorOf(id)),
            label: Text(lore.tagName(id)),
            visualDensity: VisualDensity.compact,
          ),
      ]);
}
