import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Asks a Cancel / [confirmLabel] question. Returns true when confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
