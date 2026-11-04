import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';

/// The name of a free item type ("text", "checkbox", "counter", "roll").
String freeItemName(AppLocalizations l10n, String type) => switch (type) {
      'text' => l10n.freeText,
      'checkbox' => l10n.freeCheckbox,
      'counter' => l10n.freeCounter,
      'resource' => l10n.freeResource,
      _ => l10n.freeRoll,
    };

/// Asks for the fields a free item of [type] has. Pass [existing] to edit an
/// item. Returns the new item, or null when cancelled.
Future<PlayItem?> editFreeItem(BuildContext context,
    {required String type, PlayItem? existing}) {
  return showDialog<PlayItem>(
    context: context,
    builder: (_) => _FreeItemDialog(type: type, existing: existing),
  );
}

class _FreeItemDialog extends StatefulWidget {
  const _FreeItemDialog({required this.type, this.existing});

  final String type;
  final PlayItem? existing;

  @override
  State<_FreeItemDialog> createState() => _FreeItemDialogState();
}

class _FreeItemDialogState extends State<_FreeItemDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _text = TextEditingController(text: widget.existing?.text);
  late final _number =
      TextEditingController(text: '${widget.existing?.value ?? 0}');
  late final _max = TextEditingController(text: '${widget.existing?.max ?? 0}');
  late final _damage = TextEditingController(text: widget.existing?.damage);

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    _number.dispose();
    _max.dispose();
    _damage.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String label,
          {bool number = false, int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          minLines: lines,
          maxLines: lines,
          keyboardType: number
              ? const TextInputType.numberWithOptions(signed: true)
              : (lines > 1 ? TextInputType.multiline : TextInputType.text),
        ),
      );

  PlayItem _result() {
    final old = widget.existing;
    final max = int.tryParse(_max.text) ?? 0;
    var value = int.tryParse(_number.text) ?? 0;
    if (widget.type == 'resource') {
      value = value < 0 ? 0 : (value > max ? max : value);
    }
    return PlayItem(
      type: widget.type,
      name: _name.text.trim(),
      text: _text.text,
      value: value,
      max: widget.type == 'resource' ? (max < 0 ? 0 : max) : 0,
      checked: old?.checked ?? false,
      damage: _damage.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(freeItemName(l10n, widget.type)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(_name, l10n.itemLabel),
          if (widget.type == 'text') _field(_text, l10n.itemText, lines: 4),
          if (widget.type == 'counter') _field(_number, l10n.itemValue, number: true),
          if (widget.type == 'resource') ...[
            _field(_number, l10n.itemCurrent, number: true),
            _field(_max, l10n.itemMax, number: true),
          ],
          if (widget.type == 'roll') ...[
            _field(_number, l10n.itemBonus, number: true),
            _field(_damage, l10n.itemDamageDice),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _result()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
