import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/money.dart';

/// Edit money as gold, silver and copper. Returns the new total in copper,
/// or null when cancelled.
Future<int?> showMoneyDialog(BuildContext context, int copper) {
  return showDialog<int>(
    context: context,
    builder: (_) => _MoneyDialog(copper: copper),
  );
}

class _MoneyDialog extends StatefulWidget {
  const _MoneyDialog({required this.copper});

  final int copper;

  @override
  State<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends State<_MoneyDialog> {
  late final _gold = TextEditingController();
  late final _silver = TextEditingController();
  late final _copper = TextEditingController();

  @override
  void initState() {
    super.initState();
    final parts = splitCopper(widget.copper);
    _gold.text = '${parts.gold}';
    _silver.text = '${parts.silver}';
    _copper.text = '${parts.copper}';
  }

  @override
  void dispose() {
    _gold.dispose();
    _silver.dispose();
    _copper.dispose();
    super.dispose();
  }

  /// An empty field counts as 0.
  int _number(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;

  Widget _field(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.editMoney),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(_gold, l10n.goldLabel),
        _field(_silver, l10n.silverLabel),
        _field(_copper, l10n.copperLabel),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            toCopper(
              gold: _number(_gold),
              silver: _number(_silver),
              copper: _number(_copper),
            ),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
