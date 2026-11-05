import 'dart:io';

import 'json_list_storage.dart';
import 'models/glossary.dart';

/// The player's glossary notes, kept in one JSON file (a plain list).
class GlossaryNoteStorage extends JsonListStorage<GlossaryNote> {
  GlossaryNoteStorage(File file)
      : super(file,
            fromJson: GlossaryNote.fromJson, toJson: (note) => note.toJson());
}
