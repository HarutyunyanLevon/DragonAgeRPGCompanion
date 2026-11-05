import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../l10n/app_localizations.dart';
import 'lore_providers.dart';

/// Asks for a color: the palette (defaults plus the player's own colors), and
/// a "+" to add any color by its hex code (#RRGGBB), which joins the palette.
/// Returns the color as an ARGB number, or null when cancelled.
Future<int?> pickLoreColor(BuildContext context, WidgetRef ref, {int? current}) {
  final lore = ref.read(loreProvider);
  if (lore == null) return Future.value(null);
  return showDialog<int>(
    context: context,
    builder: (_) => _ColorDialog(
      palette: [...lorePalette, ...lore.data.palette],
      current: current,
      onNewColor: (color) =>
          saveLore(ref, addPaletteColor(lore.data, color)),
    ),
  );
}

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({
    required this.palette,
    required this.current,
    required this.onNewColor,
  });

  final List<int> palette;
  final int? current;
  final Future<void> Function(int color) onNewColor;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  final _hex = TextEditingController();
  bool _adding = false;
  bool _badHex = false;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  Future<void> _addColor() async {
    final color = parseHexColor(_hex.text);
    if (color == null) {
      setState(() => _badHex = true);
      return;
    }
    await widget.onNewColor(color);
    if (mounted) Navigator.pop(context, color);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = parseHexColor(_hex.text);

    return AlertDialog(
      title: Text(l10n.loreColor),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final color in widget.palette)
              _Swatch(
                color: Color(color),
                selected: color == widget.current,
                onTap: () => Navigator.pop(context, color),
              ),
            IconButton.outlined(
              icon: const Icon(Icons.add),
              tooltip: l10n.loreNewColor,
              onPressed: () => setState(() => _adding = true),
            ),
          ]),
          if (_adding) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _hex,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.loreHex,
                    errorText: _badHex ? l10n.loreBadHex : null,
                  ),
                  onChanged: (_) => setState(() => _badHex = false),
                  onSubmitted: (_) => _addColor(),
                ),
              ),
              const SizedBox(width: 12),
              if (parsed != null) _Swatch(color: Color(parsed), selected: false),
              IconButton(icon: const Icon(Icons.check), onPressed: _addColor),
            ]),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.black87)
              : null,
        ),
      );
}
