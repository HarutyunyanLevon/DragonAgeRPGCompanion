import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/glossary.dart';
import 'glossary_notes.dart';

/// Asks for the title and text of a glossary note and saves it. Without
/// [note] a new note is added, with [note] that note is changed.
Future<void> showNoteDialog(
  BuildContext context,
  WidgetRef ref, {
  GlossaryNote? note,
}) async {
  final l10n = AppLocalizations.of(context);
  final notes = ref.read(glossaryNotesProvider.notifier);
  final title = TextEditingController(text: note?.title ?? '');
  final text = TextEditingController(text: note?.text ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(note == null ? l10n.newNote : l10n.editItem),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: title,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.noteTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(labelText: l10n.noteText),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );

  final newTitle = title.text.trim();
  final newText = text.text.trim();
  // The controllers are not disposed here: the closing dialog still uses them.

  // A note needs a title; an empty one is dropped silently.
  if (saved != true || newTitle.isEmpty) return;
  if (note == null) {
    await notes.add(newTitle, newText);
  } else {
    await notes.replace(note.copyWith(title: newTitle, text: newText));
  }
}
