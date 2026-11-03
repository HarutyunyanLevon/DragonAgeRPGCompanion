import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shows [content] in a dialog with a Close button.
Future<void> showInfoDialog(BuildContext context, Widget content) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: SingleChildScrollView(child: content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(AppLocalizations.of(dialogContext).close),
        ),
      ],
    ),
  );
}
