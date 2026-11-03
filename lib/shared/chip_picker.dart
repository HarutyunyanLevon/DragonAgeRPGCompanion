import 'package:flutter/material.dart';

/// Chips to pick from, with a description box under them for the chip
/// tapped last. Tapping a chip picks (or unpicks) it AND shows it.
///
/// With [limit] 1 it works like radio buttons: tapping another chip switches.
/// Otherwise chips that are not picked are disabled once [limit] is reached.
class ChipPicker extends StatefulWidget {
  const ChipPicker({
    super.key,
    required this.options,
    required this.picked,
    required this.limit,
    required this.onToggle,
    required this.describe,
  });

  /// (id, label) of every choice.
  final List<(String, String)> options;
  final List<String> picked;
  final int limit;
  final ValueChanged<String> onToggle;

  /// The description of the choice with this id.
  final Widget Function(String id) describe;

  @override
  State<ChipPicker> createState() => _ChipPickerState();
}

class _ChipPickerState extends State<ChipPicker> {
  String? _shown;

  bool _canTap(String id) =>
      widget.limit == 1 ||
      widget.picked.contains(id) ||
      widget.picked.length < widget.limit;

  @override
  Widget build(BuildContext context) {
    final shown = _shown;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final (id, label) in widget.options)
          FilterChip(
            label: Text(label),
            selected: widget.picked.contains(id),
            onSelected: _canTap(id)
                ? (_) {
                    setState(() => _shown = id);
                    widget.onToggle(id);
                  }
                : null,
          ),
      ]),
      if (shown != null)
        Card(
          margin: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: widget.describe(shown),
          ),
        ),
    ]);
  }
}
