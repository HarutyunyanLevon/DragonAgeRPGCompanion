import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Asks for an amount. Returns it negative for Lose and positive for Gain,
/// null when cancelled or empty.
Future<int?> askAmount(BuildContext context, String title) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();

  int? answer(bool gain) {
    final amount = int.tryParse(controller.text);
    if (amount == null) return null;
    return gain ? amount : -amount;
  }

  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.amount),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, answer(false)),
          child: Text(l10n.lose),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, answer(true)),
          child: Text(l10n.gain),
        ),
      ],
    ),
  );
}
