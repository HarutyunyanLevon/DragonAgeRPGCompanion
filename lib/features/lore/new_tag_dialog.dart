import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../l10n/app_localizations.dart';
import 'lore_providers.dart';

/// Asks for the name of a new tag. Returns it, or null when cancelled or empty.
Future<String?> askTagName(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final field = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.loreNewTag),
      content: TextField(
        controller: field,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.loreName),
        onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, field.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  // Not disposed here: the dialog is still fading out and its text field
  // uses the controller (disposing it crashed when Esc closed the dialog).
  return (name == null || name.isEmpty) ? null : name;
}

/// Asks for a name and saves the new tag (the Codex chip and the menu use it;
/// the entry form adds the tag to its own copy instead).
Future<void> addTagWithDialog(BuildContext context, WidgetRef ref) async {
  final name = await askTagName(context);
  final lore = ref.read(loreProvider);
  if (name == null || lore == null) return;
  final (data, _) = createTag(lore.data, lore.tags, name);
  await saveLore(ref, data);
}
